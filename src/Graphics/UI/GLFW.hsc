{-# LANGUAGE    ForeignFunctionInterface #-}
{-# OPTIONS_GHC -fno-warn-orphans        #-}

#include <GLFW/glfw3.h>

module Graphics.UI.GLFW
  ( init
  , terminate
  , getVersion
  , getVersionString
  , setErrorCallback
  , getMonitors
  , getPrimaryMonitor
  , getMonitorPos
  , getMonitorPhysicalSize
  , getMonitorName
  , setMonitorCallback
  , getVideoModes
  , getVideoMode
  , setGamma
  , setGammaRamp
  , getGammaRamp
  , defaultWindowHints
  , windowHint
  , createWindow
  , destroyWindow
  , windowShouldClose
  , setWindowShouldClose
  , setWindowTitle
  , getWindowPos
  , setWindowPos
  , getWindowSize
  , setWindowSize
  , getFramebufferSize
  , iconifyWindow
  , restoreWindow
  , showWindow
  , hideWindow
  , getWindowMonitor
  -- related to glfwGetWindowAttrib ----.
  , getWindowFocused                 -- |
  , getWindowIconified               -- |
  , getWindowResizable               -- |
  , getWindowDecorated               -- |
  , getWindowVisible                 -- |
  , getWindowClientAPI               -- |
  , getWindowContextVersionMajor     -- |
  , getWindowContextVersionMinor     -- |
  , getWindowContextVersionRevision  -- |
  , getWindowContextRobustness       -- |
  , getWindowOpenGLForwardCompat     -- |
  , getWindowOpenGLDebugContext      -- |
  , getWindowOpenGLProfile           -- |
  -- -----------------------------------'
  -- setWindowUserPointer
  -- getWindowUserPointer
  , setWindowPosCallback
  , setWindowSizeCallback
  , setWindowCloseCallback
  , setWindowRefreshCallback
  , setWindowFocusCallback
  , setWindowIconifyCallback
  , setFramebufferSizeCallback
  , pollEvents
  , waitEvents
  -- related to glfw{GS}etInputMode ---.
  , getCursorInputMode              -- |
  , setCursorInputMode              -- |
  , getStickyKeysInputMode          -- |
  , setStickyKeysInputMode          -- |
  , getStickyMouseButtonsInputMode  -- |
  , setStickyMouseButtonsInputMode  -- |
  -- ----------------------------------'
  , getKey
  , getMouseButton
  , getCursorPos
  , setCursorPos
  , setKeyCallback
  , setCharCallback
  , setMouseButtonCallback
  , setCursorPosCallback
  , setCursorEnterCallback
  , setScrollCallback
  , joystickPresent
  , getJoystickAxes
  , getJoystickButtons
  , getJoystickName
  , setClipboardString
  , getClipboardString
  , getTime
  , setTime
  , makeContextCurrent
  , getCurrentContext
  , swapBuffers
  , swapInterval
  , extensionSupported
  -- getProcAddress

  , Version(..)
  , Joystick(..)
  , GammaRamp(..)
  , Key(..)
  , KeyState(..)
  , Window
  , Error(..)
  , FocusState(..)
  , IconifyState(..)
  , MouseButton(..)
  , MouseButtonState(..)
  , ModifierKeys(..)
  , MonitorState(..)
  , CursorState(..)
  ) where

--------------------------------------------------------------------------------

import Prelude hiding (init)
import Control.Monad         (when)
import Data.IORef            (IORef, atomicModifyIORef', newIORef)
import Foreign.C.String      (peekCString, withCString)
import Foreign.C.Types       (CChar(..), CDouble(..), CFloat(..), CInt(..), CUShort(..), CUChar(..), CUInt(..))
import Foreign.Marshal.Alloc (alloca, allocaBytes)
import Foreign.Marshal.Array (advancePtr, allocaArray, withArray, peekArray)
import Foreign.Ptr           (FunPtr, Ptr, freeHaskellFunPtr, nullFunPtr, nullPtr)
import Foreign.Storable      (Storable(..))
import System.IO.Unsafe      (unsafePerformIO)

import Graphics.UI.GLFW.Internal.C           (C(..))
import Graphics.UI.GLFW.Internal.Instances.C ()
import Graphics.UI.GLFW.Types

--------------------------------------------------------------------------------

-- TODO: which of these can be marked "unsafe"?
foreign import ccall glfwInit                       :: IO CInt
foreign import ccall glfwTerminate                  :: IO ()
foreign import ccall glfwGetVersion                 :: Ptr CInt -> Ptr CInt -> Ptr CInt -> IO ()
foreign import ccall glfwGetVersionString           :: IO (Ptr CChar)
foreign import ccall glfwSetErrorCallback           :: FunPtr GlfwErrorCallback -> IO (FunPtr GlfwErrorCallback)
foreign import ccall glfwGetMonitors                :: Ptr CInt -> IO (Ptr (Ptr GlfwMonitor))
foreign import ccall glfwGetPrimaryMonitor          :: IO (Ptr GlfwMonitor)
foreign import ccall glfwGetMonitorPos              :: Ptr GlfwMonitor -> Ptr CInt -> Ptr CInt -> IO ()
foreign import ccall glfwGetMonitorPhysicalSize     :: Ptr GlfwMonitor -> Ptr CInt -> Ptr CInt -> IO ()
foreign import ccall glfwGetMonitorName             :: Ptr GlfwMonitor -> IO (Ptr CChar)
foreign import ccall glfwSetMonitorCallback         :: FunPtr GlfwMonitorCallback -> IO (FunPtr GlfwMonitorCallback)
foreign import ccall glfwGetVideoModes              :: Ptr GlfwMonitor -> Ptr CInt -> IO (Ptr GlfwVideoMode)
foreign import ccall glfwGetVideoMode               :: Ptr GlfwMonitor -> IO (Ptr GlfwVideoMode)
foreign import ccall glfwSetGamma                   :: Ptr GlfwMonitor -> CFloat -> IO ()
foreign import ccall glfwSetGammaRamp               :: Ptr GlfwMonitor -> Ptr GlfwGammaRamp -> IO ()
foreign import ccall glfwGetGammaRamp               :: Ptr GlfwMonitor -> IO (Ptr GlfwGammaRamp)
foreign import ccall glfwDefaultWindowHints         :: IO ()
foreign import ccall glfwWindowHint                 :: CInt -> CInt -> IO ()
foreign import ccall glfwCreateWindow               :: CInt -> CInt -> Ptr CChar -> Ptr GlfwMonitor -> Ptr GlfwWindow -> IO (Ptr GlfwWindow)
foreign import ccall glfwDestroyWindow              :: Ptr GlfwWindow -> IO ()
foreign import ccall glfwWindowShouldClose          :: Ptr GlfwWindow -> IO CInt
foreign import ccall glfwSetWindowShouldClose       :: Ptr GlfwWindow -> CInt -> IO ()
foreign import ccall glfwSetWindowTitle             :: Ptr GlfwWindow -> Ptr CChar -> IO ()
foreign import ccall glfwGetWindowPos               :: Ptr GlfwWindow -> Ptr CInt -> Ptr CInt -> IO ()
foreign import ccall glfwSetWindowPos               :: Ptr GlfwWindow -> CInt -> CInt -> IO ()
foreign import ccall glfwGetWindowSize              :: Ptr GlfwWindow -> Ptr CInt -> Ptr CInt -> IO ()
foreign import ccall glfwSetWindowSize              :: Ptr GlfwWindow -> CInt -> CInt -> IO ()
foreign import ccall glfwGetFramebufferSize         :: Ptr GlfwWindow -> Ptr CInt -> Ptr CInt -> IO ()
foreign import ccall glfwIconifyWindow              :: Ptr GlfwWindow -> IO ()
foreign import ccall glfwRestoreWindow              :: Ptr GlfwWindow -> IO ()
foreign import ccall glfwShowWindow                 :: Ptr GlfwWindow -> IO ()
foreign import ccall glfwHideWindow                 :: Ptr GlfwWindow -> IO ()
foreign import ccall glfwGetWindowMonitor           :: Ptr GlfwWindow -> IO (Ptr GlfwMonitor)
foreign import ccall glfwGetWindowAttrib            :: Ptr GlfwWindow -> CInt -> IO CInt
foreign import ccall glfwSetWindowPosCallback       :: Ptr GlfwWindow -> FunPtr GlfwWindowPosCallback       -> IO (FunPtr GlfwWindowPosCallback)
foreign import ccall glfwSetWindowSizeCallback      :: Ptr GlfwWindow -> FunPtr GlfwWindowSizeCallback      -> IO (FunPtr GlfwWindowSizeCallback)
foreign import ccall glfwSetWindowCloseCallback     :: Ptr GlfwWindow -> FunPtr GlfwWindowCloseCallback     -> IO (FunPtr GlfwWindowCloseCallback)
foreign import ccall glfwSetWindowRefreshCallback   :: Ptr GlfwWindow -> FunPtr GlfwWindowRefreshCallback   -> IO (FunPtr GlfwWindowRefreshCallback)
foreign import ccall glfwSetWindowFocusCallback     :: Ptr GlfwWindow -> FunPtr GlfwWindowFocusCallback     -> IO (FunPtr GlfwWindowFocusCallback)
foreign import ccall glfwSetWindowIconifyCallback   :: Ptr GlfwWindow -> FunPtr GlfwWindowIconifyCallback   -> IO (FunPtr GlfwWindowIconifyCallback)
foreign import ccall glfwSetFramebufferSizeCallback :: Ptr GlfwWindow -> FunPtr GlfwFramebufferSizeCallback -> IO (FunPtr GlfwFramebufferSizeCallback)
foreign import ccall glfwPollEvents                 :: IO ()
foreign import ccall glfwWaitEvents                 :: IO ()
foreign import ccall glfwGetInputMode               :: Ptr GlfwWindow -> CInt -> IO CInt
foreign import ccall glfwSetInputMode               :: Ptr GlfwWindow -> CInt -> CInt -> IO ()
foreign import ccall glfwGetKey                     :: Ptr GlfwWindow -> CInt -> IO CInt
foreign import ccall glfwGetMouseButton             :: Ptr GlfwWindow -> CInt -> IO CInt
foreign import ccall glfwGetCursorPos               :: Ptr GlfwWindow -> Ptr CDouble -> Ptr CDouble -> IO ()
foreign import ccall glfwSetCursorPos               :: Ptr GlfwWindow -> CDouble -> CDouble -> IO ()
foreign import ccall glfwSetKeyCallback             :: Ptr GlfwWindow -> FunPtr GlfwKeyCallback -> IO (FunPtr GlfwKeyCallback)
foreign import ccall glfwSetCharCallback            :: Ptr GlfwWindow -> FunPtr GlfwCharCallback -> IO (FunPtr GlfwCharCallback)
foreign import ccall glfwSetMouseButtonCallback     :: Ptr GlfwWindow -> FunPtr GlfwMouseButtonCallback -> IO (FunPtr GlfwMouseButtonCallback)
foreign import ccall glfwSetCursorPosCallback       :: Ptr GlfwWindow -> FunPtr GlfwCursorPosCallback -> IO (FunPtr GlfwCursorPosCallback)
foreign import ccall glfwSetCursorEnterCallback     :: Ptr GlfwWindow -> FunPtr GlfwCursorEnterCallback -> IO (FunPtr GlfwCursorEnterCallback)
foreign import ccall glfwSetScrollCallback          :: Ptr GlfwWindow -> FunPtr GlfwScrollCallback -> IO (FunPtr GlfwScrollCallback)
foreign import ccall glfwJoystickPresent            :: CInt -> IO CInt
foreign import ccall glfwGetJoystickAxes            :: CInt -> Ptr CInt -> IO (Ptr CFloat)
foreign import ccall glfwGetJoystickButtons         :: CInt -> Ptr CInt -> IO (Ptr CUChar)
foreign import ccall glfwGetJoystickName            :: CInt -> IO (Ptr CChar)
foreign import ccall glfwSetClipboardString         :: Ptr GlfwWindow -> Ptr CChar -> IO ()
foreign import ccall glfwGetClipboardString         :: Ptr GlfwWindow -> IO (Ptr CChar)
foreign import ccall glfwGetTime                    :: IO CDouble
foreign import ccall glfwSetTime                    :: CDouble -> IO ()
foreign import ccall glfwMakeContextCurrent         :: Ptr GlfwWindow -> IO ()
foreign import ccall glfwGetCurrentContext          :: IO (Ptr GlfwWindow)
foreign import ccall glfwSwapBuffers                :: Ptr GlfwWindow -> IO ()
foreign import ccall glfwSwapInterval               :: CInt -> IO ()
foreign import ccall glfwExtensionSupported         :: Ptr CChar -> IO CInt

-- glfwSetWindowUserPointer
-- glfwGetWindowUserPointer
-- glfwGetProcAddress

type GlfwErrorCallback           = CInt -> Ptr CChar                              -> IO ()
type GlfwMonitorCallback         = Ptr GlfwMonitor -> CInt                        -> IO ()
type GlfwCharCallback            = Ptr GlfwWindow -> CInt                         -> IO ()
type GlfwCursorEnterCallback     = Ptr GlfwWindow -> CInt                         -> IO ()
type GlfwCursorPosCallback       = Ptr GlfwWindow -> CDouble -> CDouble           -> IO ()
type GlfwFramebufferSizeCallback = Ptr GlfwWindow -> CInt -> CInt                 -> IO ()
type GlfwKeyCallback             = Ptr GlfwWindow -> CInt -> CInt -> CInt -> CInt -> IO ()
type GlfwMouseButtonCallback     = Ptr GlfwWindow -> CInt -> CInt -> CInt         -> IO ()
type GlfwScrollCallback          = Ptr GlfwWindow -> CDouble -> CDouble           -> IO ()
type GlfwWindowCloseCallback     = Ptr GlfwWindow                                 -> IO ()
type GlfwWindowFocusCallback     = Ptr GlfwWindow -> CInt                         -> IO ()
type GlfwWindowIconifyCallback   = Ptr GlfwWindow -> CInt                         -> IO ()
type GlfwWindowPosCallback       = Ptr GlfwWindow -> CInt -> CInt                 -> IO ()
type GlfwWindowRefreshCallback   = Ptr GlfwWindow                                 -> IO ()
type GlfwWindowSizeCallback      = Ptr GlfwWindow -> CInt -> CInt                 -> IO ()

foreign import ccall "wrapper" wrapGlfwErrorCallback           :: GlfwErrorCallback           -> IO (FunPtr GlfwErrorCallback          )
foreign import ccall "wrapper" wrapGlfwMonitorCallback         :: GlfwMonitorCallback         -> IO (FunPtr GlfwMonitorCallback        )
foreign import ccall "wrapper" wrapGlfwCharCallback            :: GlfwCharCallback            -> IO (FunPtr GlfwCharCallback           )
foreign import ccall "wrapper" wrapGlfwCursorEnterCallback     :: GlfwCursorEnterCallback     -> IO (FunPtr GlfwCursorEnterCallback    )
foreign import ccall "wrapper" wrapGlfwCursorPosCallback       :: GlfwCursorPosCallback       -> IO (FunPtr GlfwCursorPosCallback      )
foreign import ccall "wrapper" wrapGlfwFramebufferSizeCallback :: GlfwFramebufferSizeCallback -> IO (FunPtr GlfwFramebufferSizeCallback)
foreign import ccall "wrapper" wrapGlfwKeyCallback             :: GlfwKeyCallback             -> IO (FunPtr GlfwKeyCallback            )
foreign import ccall "wrapper" wrapGlfwMouseButtonCallback     :: GlfwMouseButtonCallback     -> IO (FunPtr GlfwMouseButtonCallback    )
foreign import ccall "wrapper" wrapGlfwScrollCallback          :: GlfwScrollCallback          -> IO (FunPtr GlfwScrollCallback         )
foreign import ccall "wrapper" wrapGlfwWindowCloseCallback     :: GlfwWindowCloseCallback     -> IO (FunPtr GlfwWindowCloseCallback    )
foreign import ccall "wrapper" wrapGlfwWindowFocusCallback     :: GlfwWindowFocusCallback     -> IO (FunPtr GlfwWindowFocusCallback    )
foreign import ccall "wrapper" wrapGlfwWindowIconifyCallback   :: GlfwWindowIconifyCallback   -> IO (FunPtr GlfwWindowIconifyCallback  )
foreign import ccall "wrapper" wrapGlfwWindowPosCallback       :: GlfwWindowPosCallback       -> IO (FunPtr GlfwWindowPosCallback      )
foreign import ccall "wrapper" wrapGlfwWindowRefreshCallback   :: GlfwWindowRefreshCallback   -> IO (FunPtr GlfwWindowRefreshCallback  )
foreign import ccall "wrapper" wrapGlfwWindowSizeCallback      :: GlfwWindowSizeCallback      -> IO (FunPtr GlfwWindowSizeCallback     )

--------------------------------------------------------------------------------

errorCallback           :: IORef (FunPtr GlfwErrorCallback)
{-# NOINLINE errorCallback           #-}
windowPosCallback       :: IORef (FunPtr GlfwWindowPosCallback)
{-# NOINLINE windowPosCallback       #-}
windowSizeCallback      :: IORef (FunPtr GlfwWindowSizeCallback)
{-# NOINLINE windowSizeCallback      #-}
windowCloseCallback     :: IORef (FunPtr GlfwWindowCloseCallback)
{-# NOINLINE windowCloseCallback     #-}
windowRefreshCallback   :: IORef (FunPtr GlfwWindowRefreshCallback)
{-# NOINLINE windowRefreshCallback   #-}
windowFocusCallback     :: IORef (FunPtr GlfwWindowFocusCallback)
{-# NOINLINE windowFocusCallback     #-}
windowIconifyCallback   :: IORef (FunPtr GlfwWindowIconifyCallback)
{-# NOINLINE windowIconifyCallback   #-}
framebufferSizeCallback :: IORef (FunPtr GlfwFramebufferSizeCallback)
{-# NOINLINE framebufferSizeCallback #-}
mouseButtonCallback     :: IORef (FunPtr GlfwMouseButtonCallback)
{-# NOINLINE mouseButtonCallback     #-}
cursorPosCallback       :: IORef (FunPtr GlfwCursorPosCallback)
{-# NOINLINE cursorPosCallback       #-}
cursorEnterCallback     :: IORef (FunPtr GlfwCursorEnterCallback)
{-# NOINLINE cursorEnterCallback     #-}
scrollCallback          :: IORef (FunPtr GlfwScrollCallback)
{-# NOINLINE scrollCallback          #-}
keyCallback             :: IORef (FunPtr GlfwKeyCallback)
{-# NOINLINE keyCallback             #-}
charCallback            :: IORef (FunPtr GlfwCharCallback)
{-# NOINLINE charCallback            #-}
monitorCallback         :: IORef (FunPtr GlfwMonitorCallback)
{-# NOINLINE monitorCallback         #-}

errorCallback           = unsafePerformIO $ newIORef nullFunPtr
windowPosCallback       = unsafePerformIO $ newIORef nullFunPtr
windowSizeCallback      = unsafePerformIO $ newIORef nullFunPtr
windowCloseCallback     = unsafePerformIO $ newIORef nullFunPtr
windowRefreshCallback   = unsafePerformIO $ newIORef nullFunPtr
windowFocusCallback     = unsafePerformIO $ newIORef nullFunPtr
windowIconifyCallback   = unsafePerformIO $ newIORef nullFunPtr
framebufferSizeCallback = unsafePerformIO $ newIORef nullFunPtr
mouseButtonCallback     = unsafePerformIO $ newIORef nullFunPtr
cursorPosCallback       = unsafePerformIO $ newIORef nullFunPtr
cursorEnterCallback     = unsafePerformIO $ newIORef nullFunPtr
scrollCallback          = unsafePerformIO $ newIORef nullFunPtr
keyCallback             = unsafePerformIO $ newIORef nullFunPtr
charCallback            = unsafePerformIO $ newIORef nullFunPtr
monitorCallback         = unsafePerformIO $ newIORef nullFunPtr

setCallback
  :: (c -> IO (FunPtr c))          -- wrapper function
  -> (h -> c)                      -- adapter function
  -> (FunPtr c -> IO (FunPtr c))   -- glfwSet*Callback function
  -> IORef (FunPtr c)              -- storage location
  -> Maybe h                       -- Haskell callback
  -> IO ()
setCallback wf af gf ior mcb = do
    ccb <- maybe (return nullFunPtr) (wf . af) mcb
    _   <- gf ccb
    storeCallback ior ccb

storeCallback :: IORef (FunPtr a) -> FunPtr a -> IO ()
storeCallback ior new = do
    prev <- atomicModifyIORef' ior (\cur -> (new, cur))
    when (prev /= nullFunPtr) $ freeHaskellFunPtr prev

--------------------------------------------------------------------------------

instance Storable GlfwVideoMode where
  sizeOf _ = (#const sizeof(GLFWvidmode))
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
      w  <- (#peek GLFWvidmode, width)       ptr :: IO CInt
      h  <- (#peek GLFWvidmode, height)      ptr :: IO CInt
      rb <- (#peek GLFWvidmode, redBits)     ptr :: IO CInt
      gb <- (#peek GLFWvidmode, greenBits)   ptr :: IO CInt
      bb <- (#peek GLFWvidmode, blueBits)    ptr :: IO CInt
      rr <- (#peek GLFWvidmode, refreshRate) ptr :: IO CInt
      return GlfwVideoMode
        { glfwVideoModeWidth       = w
        , glfwVideoModeHeight      = h
        , glfwVideoModeRedBits     = rb
        , glfwVideoModeGreenBits   = gb
        , glfwVideoModeBlueBits    = bb
        , glfwVideoModeRefreshRate = rr
        }

--------------------------------------------------------------------------------

init :: IO Bool
init =
    fromC `fmap` glfwInit

-- TODO free stored callback FunPtrs here
terminate :: IO ()
terminate =
    glfwTerminate

getVersion :: IO Version
getVersion =
    allocaArray 3 $ \p -> do
        let p0 = p
            p1 = p `advancePtr` 1
            p2 = p `advancePtr` 2
        glfwGetVersion p0 p1 p2
        v0 <- fromC `fmap` peek p0
        v1 <- fromC `fmap` peek p1
        v2 <- fromC `fmap` peek p2
        return $ Version v0 v1 v2

getVersionString :: IO String
getVersionString =
    glfwGetVersionString >>= peekCString

setErrorCallback :: Maybe ErrorCallback -> IO ()
setErrorCallback =
    setCallback
        wrapGlfwErrorCallback
        (\cb a0 a1 -> do
            s <- peekCString a1
            cb (fromC a0) s)
        glfwSetErrorCallback
        errorCallback

getMonitors :: IO (Maybe [Monitor])
getMonitors =
    alloca $ \pn -> do
        p <- glfwGetMonitors pn
        n <- fromC `fmap` peek pn
        if p == nullPtr || n <= 0
          then return Nothing
          else (Just . map fromC) `fmap` peekArray n p

getPrimaryMonitor :: IO (Maybe Monitor)
getPrimaryMonitor = do
    p <- glfwGetPrimaryMonitor
    return $
      if p == nullPtr
        then Nothing
        else Just $ fromC p

getMonitorPos :: Monitor -> IO (Int, Int)
getMonitorPos mon =
    allocaArray 2 $ \p -> do
        let px = p
            py = p `advancePtr` 1
        glfwGetMonitorPos (toC mon) px py
        x <- fromC `fmap` peek px
        y <- fromC `fmap` peek py
        return (x, y)

getMonitorPhysicalSize :: Monitor -> IO (Int, Int)
getMonitorPhysicalSize mon =
    allocaArray 2 $ \p -> do
        let pw = p
            ph = p `advancePtr` 1
        glfwGetMonitorPhysicalSize (toC mon) pw ph
        w <- fromC `fmap` peek pw
        h <- fromC `fmap` peek ph
        return (w, h)

getMonitorName :: Monitor -> IO (Maybe String)
getMonitorName mon = do
    p <- glfwGetMonitorName (toC mon)
    if p == nullPtr
      then return Nothing
      else Just `fmap` peekCString p

setMonitorCallback :: Maybe MonitorCallback -> IO ()
setMonitorCallback mcb = do
    ccb <- case mcb of
        (Just cb) ->
            wrapGlfwMonitorCallback $ \cp ci ->
                cb (fromC cp) (fromC ci)
        Nothing -> return nullFunPtr
    _ <- glfwSetMonitorCallback ccb
    storeCallback monitorCallback ccb

getVideoModes :: Monitor -> IO (Maybe [VideoMode])
getVideoModes mon =
    alloca $ \pn -> do
        p <- glfwGetVideoModes (toC mon) pn
        n <- fromC `fmap` peek pn
        if p == nullPtr || n <= 0
          then return Nothing
          else (Just . map fromC) `fmap` peekArray n p

getVideoMode :: Monitor -> IO (Maybe VideoMode)
getVideoMode mon = do
    p <- glfwGetVideoMode (toC mon)
    if p == nullPtr
      then return Nothing
      else (Just . fromC) `fmap` peek p

setGamma :: Monitor -> Double -> IO ()
setGamma mon e =
    glfwSetGamma (toC mon) (toC e)

getGammaRamp :: Monitor -> IO (Maybe GammaRamp)
getGammaRamp m = do
    p <- glfwGetGammaRamp (toC m)
    if p == nullPtr
      then return Nothing
      else do
          pr <- (#peek GLFWgammaramp, red)   p :: IO (Ptr CUShort)
          pg <- (#peek GLFWgammaramp, green) p :: IO (Ptr CUShort)
          pb <- (#peek GLFWgammaramp, blue)  p :: IO (Ptr CUShort)
          cn <- (#peek GLFWgammaramp, size)  p :: IO CUInt
          let n = fromC cn
          r <- map fromC `fmap` peekArray n pr
          g <- map fromC `fmap` peekArray n pg
          b <- map fromC `fmap` peekArray n pb
          return $ Just GammaRamp
            { gammaRampRed   = r
            , gammaRampGreen = g
            , gammaRampBlue  = b
            , gammaRampSize  = n
            }

setGammaRamp :: Monitor -> GammaRamp -> IO ()
setGammaRamp m gr =
    let r = map toC $ gammaRampRed   gr :: [CUShort]
        g = map toC $ gammaRampGreen gr :: [CUShort]
        b = map toC $ gammaRampBlue  gr :: [CUShort]
        n =     toC $ gammaRampSize  gr :: CUInt
    in allocaBytes (#size GLFWgammaramp) $ \pgr ->
       withArray r $ \pr ->
       withArray g $ \pg ->
       withArray b $ \pb -> do
           (#poke GLFWgammaramp, red)   pgr pr
           (#poke GLFWgammaramp, green) pgr pg
           (#poke GLFWgammaramp, blue)  pgr pb
           (#poke GLFWgammaramp, size)  pgr n
           glfwSetGammaRamp (toC m) pgr

defaultWindowHints :: IO ()
defaultWindowHints =
    glfwDefaultWindowHints

windowHint :: WindowHint -> IO ()
windowHint wh = do
    let (t, v) = case wh of
                   (WindowHint'Resizable           x) -> ((#const GLFW_RESIZABLE),             toC x)
                   (WindowHint'Visible             x) -> ((#const GLFW_VISIBLE),               toC x)
                   (WindowHint'Decorated           x) -> ((#const GLFW_DECORATED),             toC x)
                   (WindowHint'RedBits             x) -> ((#const GLFW_RED_BITS),              toC x)
                   (WindowHint'GreenBits           x) -> ((#const GLFW_GREEN_BITS),            toC x)
                   (WindowHint'BlueBits            x) -> ((#const GLFW_BLUE_BITS),             toC x)
                   (WindowHint'AlphaBits           x) -> ((#const GLFW_ALPHA_BITS),            toC x)
                   (WindowHint'DepthBits           x) -> ((#const GLFW_DEPTH_BITS),            toC x)
                   (WindowHint'StencilBits         x) -> ((#const GLFW_STENCIL_BITS),          toC x)
                   (WindowHint'AccumRedBits        x) -> ((#const GLFW_ACCUM_RED_BITS),        toC x)
                   (WindowHint'AccumGreenBits      x) -> ((#const GLFW_ACCUM_GREEN_BITS),      toC x)
                   (WindowHint'AccumBlueBits       x) -> ((#const GLFW_ACCUM_BLUE_BITS),       toC x)
                   (WindowHint'AccumAlphaBits      x) -> ((#const GLFW_ACCUM_ALPHA_BITS),      toC x)
                   (WindowHint'AuxBuffers          x) -> ((#const GLFW_AUX_BUFFERS),           toC x)
                   (WindowHint'Samples             x) -> ((#const GLFW_SAMPLES),               toC x)
                   (WindowHint'RefreshRate         x) -> ((#const GLFW_REFRESH_RATE),          toC x)
                   (WindowHint'Stereo              x) -> ((#const GLFW_STEREO),                toC x)
                   (WindowHint'sRGBCapable         x) -> ((#const GLFW_SRGB_CAPABLE),          toC x)
                   (WindowHint'ClientAPI           x) -> ((#const GLFW_CLIENT_API),            toC x)
                   (WindowHint'ContextVersionMajor x) -> ((#const GLFW_CONTEXT_VERSION_MAJOR), toC x)
                   (WindowHint'ContextVersionMinor x) -> ((#const GLFW_CONTEXT_VERSION_MINOR), toC x)
                   (WindowHint'ContextRobustness   x) -> ((#const GLFW_CONTEXT_ROBUSTNESS),    toC x)
                   (WindowHint'OpenGLForwardCompat x) -> ((#const GLFW_OPENGL_FORWARD_COMPAT), toC x)
                   (WindowHint'OpenGLDebugContext  x) -> ((#const GLFW_OPENGL_DEBUG_CONTEXT),  toC x)
                   (WindowHint'OpenGLProfile       x) -> ((#const GLFW_OPENGL_PROFILE),        toC x)
    glfwWindowHint t v

createWindow :: Int -> Int -> String -> Maybe Monitor -> Maybe Window -> IO (Maybe Window)
createWindow w h title mmon mwin =
    withCString title $ \ptitle -> do
        p <- glfwCreateWindow
          (toC w)
          (toC h)
          ptitle
          (maybe nullPtr toC mmon)
          (maybe nullPtr toC mwin)
        return $ if p == nullPtr
          then Nothing
          else Just $ fromC p

destroyWindow :: Window -> IO ()
destroyWindow =
    glfwDestroyWindow . toC

windowShouldClose :: Window -> IO Bool
windowShouldClose win =
    fromC `fmap` glfwWindowShouldClose (toC win)

setWindowShouldClose :: Window -> Bool -> IO ()
setWindowShouldClose win b =
    glfwSetWindowShouldClose (toC win) (toC b)

setWindowTitle :: Window -> String -> IO ()
setWindowTitle win title =
    withCString title $ \ptitle ->
        glfwSetWindowTitle (toC win) ptitle

getWindowPos :: Window -> IO (Int, Int)
getWindowPos win =
    allocaArray 2 $ \pa -> do
        let px = pa
            py = pa `advancePtr` 1
        glfwGetWindowPos (toC win) px py
        x <- fromC `fmap` peek px
        y <- fromC `fmap` peek py
        return (x, y)

setWindowPos :: Window -> Int -> Int -> IO ()
setWindowPos win x y =
    glfwSetWindowPos (toC win) (toC x) (toC y)

getWindowSize :: Window -> IO (Int, Int)
getWindowSize win =
    allocaArray 2 $ \pa -> do
        let pw = pa
            ph = pa `advancePtr` 1
        glfwGetWindowSize (toC win) pw ph
        w <- fromC `fmap` peek pw
        h <- fromC `fmap` peek ph
        return (w, h)

setWindowSize :: Window -> Int -> Int -> IO ()
setWindowSize win w h =
    glfwSetWindowSize (toC win) (toC w) (toC h)

getFramebufferSize :: Window -> IO (Int, Int)
getFramebufferSize win =
    allocaArray 2 $ \pa -> do
        let pw = pa
            ph = pa `advancePtr` 1
        glfwGetFramebufferSize (toC win) pw ph
        w <- fromC `fmap` peek pw
        h <- fromC `fmap` peek ph
        return (w, h)

iconifyWindow :: Window -> IO ()
iconifyWindow =
    glfwIconifyWindow . toC

restoreWindow :: Window -> IO ()
restoreWindow =
    glfwRestoreWindow . toC

showWindow :: Window -> IO ()
showWindow =
    glfwShowWindow . toC

hideWindow :: Window -> IO ()
hideWindow =
    glfwHideWindow . toC

getWindowMonitor :: Window -> IO (Maybe Monitor)
getWindowMonitor win = do
    p <- glfwGetWindowMonitor (toC win)
    return $ if p == nullPtr
      then Nothing
      else Just $ fromC p

-- start of functions related to glfwGetWindowAttrib

getWindowFocused :: Window -> IO FocusState
getWindowFocused win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_FOCUSED)

getWindowIconified :: Window -> IO IconifyState
getWindowIconified win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_ICONIFIED)

getWindowResizable :: Window -> IO Bool
getWindowResizable win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_RESIZABLE)

getWindowDecorated :: Window -> IO Bool
getWindowDecorated win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_DECORATED)

getWindowVisible :: Window -> IO Bool
getWindowVisible win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_VISIBLE)

getWindowClientAPI :: Window -> IO ClientAPI
getWindowClientAPI win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_CLIENT_API)

getWindowContextVersionMajor :: Window -> IO Int
getWindowContextVersionMajor win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_CONTEXT_VERSION_MAJOR)

getWindowContextVersionMinor :: Window -> IO Int
getWindowContextVersionMinor win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_CONTEXT_VERSION_MINOR)

getWindowContextVersionRevision :: Window -> IO Int
getWindowContextVersionRevision win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_CONTEXT_REVISION)

getWindowContextRobustness :: Window -> IO ContextRobustness
getWindowContextRobustness win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_CONTEXT_ROBUSTNESS)

getWindowOpenGLForwardCompat :: Window -> IO Bool
getWindowOpenGLForwardCompat win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_OPENGL_FORWARD_COMPAT)

getWindowOpenGLDebugContext :: Window -> IO Bool
getWindowOpenGLDebugContext win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_OPENGL_DEBUG_CONTEXT)

getWindowOpenGLProfile :: Window -> IO OpenGLProfile
getWindowOpenGLProfile win =
    fromC `fmap` glfwGetWindowAttrib (toC win) (#const GLFW_OPENGL_PROFILE)

-- end of functions related to glfwGetWindowAttrib

setWindowPosCallback :: Window -> Maybe WindowPosCallback -> IO ()
setWindowPosCallback win =
    setCallback
        wrapGlfwWindowPosCallback
        (\cb a0 a1 a2 ->
            cb (fromC a0) (fromC a1) (fromC a2))
        (glfwSetWindowPosCallback (toC win))
        windowPosCallback

setWindowSizeCallback :: Window -> Maybe WindowSizeCallback -> IO ()
setWindowSizeCallback win =
    setCallback
        wrapGlfwWindowSizeCallback
        (\cb a0 a1 a2 ->
            cb (fromC a0) (fromC a1) (fromC a2))
        (glfwSetWindowSizeCallback (toC win))
        windowSizeCallback

setWindowCloseCallback :: Window -> Maybe WindowCloseCallback -> IO ()
setWindowCloseCallback win =
    setCallback
        wrapGlfwWindowCloseCallback
        (. fromC)
        (glfwSetWindowCloseCallback (toC win))
        windowCloseCallback

setWindowRefreshCallback :: Window -> Maybe WindowRefreshCallback -> IO ()
setWindowRefreshCallback win =
    setCallback
        wrapGlfwWindowRefreshCallback
        (. fromC)
        (glfwSetWindowRefreshCallback (toC win))
        windowRefreshCallback

setWindowFocusCallback :: Window -> Maybe WindowFocusCallback -> IO ()
setWindowFocusCallback win =
    setCallback
        wrapGlfwWindowFocusCallback
        (\cb a0 a1 -> cb (fromC a0) (fromC a1))
        (glfwSetWindowFocusCallback (toC win))
        windowFocusCallback

setWindowIconifyCallback :: Window -> Maybe WindowIconifyCallback -> IO ()
setWindowIconifyCallback win =
    setCallback
        wrapGlfwWindowIconifyCallback
        (\cb a0 a1 -> cb (fromC a0) (fromC a1))
        (glfwSetWindowIconifyCallback (toC win))
        windowIconifyCallback

setFramebufferSizeCallback :: Window -> Maybe FramebufferSizeCallback -> IO ()
setFramebufferSizeCallback win =
    setCallback
        wrapGlfwFramebufferSizeCallback
        (\cb a0 a1 a2 -> cb (fromC a0) (fromC a1) (fromC a2))
        (glfwSetFramebufferSizeCallback (toC win))
        framebufferSizeCallback

pollEvents :: IO ()
pollEvents = glfwPollEvents

waitEvents :: IO ()
waitEvents = glfwWaitEvents

-- start of glfw{GS}etInputMode-related functions

getCursorInputMode :: Window -> IO CursorInputMode
getCursorInputMode win =
    fromC `fmap` glfwGetInputMode (toC win) (#const GLFW_CURSOR)

setCursorInputMode :: Window -> CursorInputMode -> IO ()
setCursorInputMode win c =
    glfwSetInputMode (toC win) (#const GLFW_CURSOR) (toC c)

getStickyKeysInputMode :: Window -> IO StickyKeysInputMode
getStickyKeysInputMode win =
    fromC `fmap` glfwGetInputMode (toC win) (#const GLFW_STICKY_KEYS)

setStickyKeysInputMode :: Window -> StickyKeysInputMode -> IO ()
setStickyKeysInputMode win sk =
    glfwSetInputMode (toC win) (#const GLFW_STICKY_KEYS) (toC sk)

getStickyMouseButtonsInputMode :: Window -> IO StickyMouseButtonsInputMode
getStickyMouseButtonsInputMode win =
    fromC `fmap` glfwGetInputMode (toC win) (#const GLFW_STICKY_MOUSE_BUTTONS)

setStickyMouseButtonsInputMode :: Window -> StickyMouseButtonsInputMode -> IO ()
setStickyMouseButtonsInputMode win smb =
    glfwSetInputMode (toC win) (#const GLFW_STICKY_MOUSE_BUTTONS) (toC smb)

-- end of glfw{GS}etInputMode-related functions

getKey :: Window -> Key -> IO KeyState
getKey win k =
    fromC `fmap` glfwGetKey (toC win) (toC k)

getMouseButton :: Window -> MouseButton -> IO MouseButtonState
getMouseButton win b =
    fromC `fmap` glfwGetMouseButton (toC win) (toC b)

getCursorPos :: Window -> IO (Double, Double)
getCursorPos win =
    allocaArray 2 $ \pa -> do
        let px = pa
            py = pa `advancePtr` 1
        glfwGetCursorPos (toC win) px py
        x <- fromC `fmap` peek px
        y <- fromC `fmap` peek py
        return (x, y)

setCursorPos :: Window -> Double -> Double -> IO ()
setCursorPos win x y =
    glfwSetCursorPos (toC win) (toC x) (toC y)

setKeyCallback :: Window -> Maybe KeyCallback -> IO ()
setKeyCallback win =
    setCallback
        wrapGlfwKeyCallback
        (\cb a0 a1 a2 a3 a4 ->
            cb (fromC a0) (fromC a1) (fromC a2) (fromC a3) (fromC a4))
        (glfwSetKeyCallback (toC win))
        keyCallback

setCharCallback :: Window -> Maybe CharCallback -> IO ()
setCharCallback win =
    setCallback
        wrapGlfwCharCallback
        (\cb a0 a1 -> cb (fromC a0) (fromC a1))
        (glfwSetCharCallback (toC win))
        charCallback

setMouseButtonCallback :: Window -> Maybe MouseButtonCallback -> IO ()
setMouseButtonCallback win =
    setCallback
        wrapGlfwMouseButtonCallback
        (\cb a0 a1 a2 a3 -> cb (fromC a0) (fromC a1) (fromC a2) (fromC a3))
        (glfwSetMouseButtonCallback (toC win))
        mouseButtonCallback

setCursorPosCallback :: Window -> Maybe CursorPosCallback -> IO ()
setCursorPosCallback win =
    setCallback
        wrapGlfwCursorPosCallback
        (\cb a0 a1 a2 -> cb (fromC a0) (fromC a1) (fromC a2))
        (glfwSetCursorPosCallback (toC win))
        cursorPosCallback

setCursorEnterCallback :: Window -> Maybe CursorEnterCallback -> IO ()
setCursorEnterCallback win =
    setCallback
        wrapGlfwCursorEnterCallback
        (\cb a0 a1 -> cb (fromC a0) (fromC a1))
        (glfwSetCursorEnterCallback (toC win))
        cursorEnterCallback

setScrollCallback :: Window -> Maybe ScrollCallback -> IO ()
setScrollCallback win =
    setCallback
        wrapGlfwScrollCallback
        (\cb a0 a1 a2 -> cb (fromC a0) (fromC a1) (fromC a2))
        (glfwSetScrollCallback (toC win))
        scrollCallback

joystickPresent :: Joystick -> IO Bool
joystickPresent js =
    fromC `fmap` glfwJoystickPresent (toC js)

getJoystickAxes :: Joystick -> IO (Maybe [Double])
getJoystickAxes js =
    alloca $ \pn -> do
        p <- glfwGetJoystickAxes (toC js) pn
        n <- fromC `fmap` peek pn
        if p == nullPtr || n <= 0
          then return Nothing
          else (Just . map fromC) `fmap` peekArray n p

getJoystickButtons :: Joystick -> IO (Maybe [JoystickButtonState])
getJoystickButtons js =
    alloca $ \pn -> do
        p <- glfwGetJoystickButtons (toC js) pn
        n <- fromC `fmap` peek pn
        if p == nullPtr || n <= 0
          then return Nothing
          else (Just . map fromC) `fmap` peekArray n p

getJoystickName :: Joystick -> IO (Maybe String)
getJoystickName js = do
    p <- glfwGetJoystickName (toC js)
    if p == nullPtr
      then return Nothing
      else Just `fmap` peekCString p

setClipboardString :: Window -> String -> IO ()
setClipboardString win s =
    withCString s (glfwSetClipboardString (toC win))

getClipboardString :: Window -> IO (Maybe String)
getClipboardString win = do
    p <- glfwGetClipboardString (toC win)
    if p == nullPtr
      then return Nothing
      else Just `fmap` peekCString p

getTime :: IO (Maybe Double)
getTime = do
    t <- fromC `fmap` glfwGetTime
    return $ if t == 0
      then Nothing
      else Just t

setTime :: Double -> IO ()
setTime =
    glfwSetTime . toC

makeContextCurrent :: Maybe Window -> IO ()
makeContextCurrent =
    glfwMakeContextCurrent . maybe nullPtr toC

getCurrentContext :: IO (Maybe Window)
getCurrentContext = do
    p <- glfwGetCurrentContext
    return $ if p == nullPtr
      then Nothing
      else Just $ fromC p

swapBuffers :: Window -> IO ()
swapBuffers =
    glfwSwapBuffers . toC

swapInterval :: Int -> IO ()
swapInterval =
    glfwSwapInterval . toC

extensionSupported :: String -> IO Bool
extensionSupported ext =
    withCString ext $ \pext ->
        fromC `fmap` glfwExtensionSupported pext

-- getProcAddress

--------------------------------------------------------------------------------

type ErrorCallback           = Error -> String                                           -> IO ()
type WindowPosCallback       = Window -> Int -> Int                                      -> IO ()
type WindowSizeCallback      = Window -> Int -> Int                                      -> IO ()
type WindowCloseCallback     = Window                                                    -> IO ()
type WindowRefreshCallback   = Window                                                    -> IO ()
type WindowFocusCallback     = Window -> FocusState                                      -> IO ()
type WindowIconifyCallback   = Window -> IconifyState                                    -> IO ()
type FramebufferSizeCallback = Window -> Int -> Int                                      -> IO ()
type MouseButtonCallback     = Window -> MouseButton -> MouseButtonState -> ModifierKeys -> IO ()
type CursorPosCallback       = Window -> Double -> Double                                -> IO ()
type CursorEnterCallback     = Window -> CursorState                                     -> IO ()
type ScrollCallback          = Window -> Double -> Double                                -> IO ()
type KeyCallback             = Window -> Key -> Int -> KeyState -> ModifierKeys          -> IO ()
type CharCallback            = Window -> Char                                            -> IO ()
type MonitorCallback         = Monitor -> MonitorState                                   -> IO ()
