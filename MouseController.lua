scriptId = "com.thalmic.MapsController"

isZoomingIn = false
isZoomingOut = false
isPanningLeft = false
isPanningUp = false
isPanningRight = false
isPanningDown = false
timerCounter = 0
timerCounter2 = 0
test = 0
initialYaw = 0

function activeAppName()
    return "Cursor Controller"
end

-- swaps waveIn and waveOut poses if left-handed
function conditionallySwapWave(pose)
    if myo.getArm() == "left" then
        if pose == "waveIn" then
            pose = "waveOut"
        elseif pose == "waveOut" then
            pose = "waveIn"
        end
    end
    return pose
end

-- called whenever pose event occurs
function onPoseEdge(pose, edge)
    
    pose = conditionallySwapWave(pose)
    
    -- lock-unlock pose handler
    if pose == "thumbToPinky" then
        if not myo.mouseControlEnabled() then -- Unlock
            if edge == "off" then
                myo.controlMouse(true)
                myo.debug("ON")
                initialYaw = 57.3 * myo.getYaw()
            elseif edge == "on" then
                myo.vibrate("medium")
            end
        elseif myo.mouseControlEnabled() then -- Lock
            if edge == "off" then
                myo.controlMouse(false)
                myo.debug("OFF")
            elseif edge == "on" then
                myo.vibrate("medium")
            end
        end
    end
    
    -- zoom in-out gesture handler
    if myo.mouseControlEnabled() then
        if pose == "fist"  then
            if edge == "on" then
                myo.vibrate("short")
                isZoomingOut = true
                -- myo.keyboard("minus", "press")
                myo.debug("fist on")
            end
            if edge == "off" then
                isZoomingOut = false
                -- myo.keyboard("minus", "up")
                myo.debug("fist off")
            end
        
        elseif pose == "fingersSpread" then
            if edge == "on" then
                myo.vibrate("short")
                isZoomingIn = true
                -- myo.keyboard("equal", "press")
                myo.debug("fingers spread on")
            end
            if edge == "off" then
                isZoomingIn = false
                -- myo.keyboard("equal", "up")
                myo.debug("fingers spread off")
            end
        end
    end
    
end

-- called every 10ms
function onPeriodic()
    -- code only executed when unlocked
    if myo.mouseControlEnabled() then
        -- counter logic to trigger keypresses at slower rate
        if isZoomingOut or isZoomingIn then
            timerCounter = timerCounter + 1
            if timerCounter == 50 then
                timerCounter = 0
            end
        else
            timerCounter = 0
        end
        
        if timerCounter2 == 10
            myo.centerMousePosition()
            if isZoomingOut and timerCounter == 1 then
                myo.keyboard("minus", "press")
                myo.debug("zooming out")
            elseif isZoomingIn and timerCounter == 1 then
                myo.keyboard("equal", "press")
                myo.debug("zooming in")
            end
            
            -- pitch controls up-down panning 
            pitch = 57.3 * myo.getPitch()
            if (myo.getXDirection() == "towardWrist") then
                pitch = pitch * -1
            end
            
            -- up-down panning conditions
            if pitch > 20 then
                myo.keyboard("up_arrow", "down")
            elseif pitch < 20 and pitch > -20 then
                myo.keyboard("up_arrow", "up")
                myo.keyboard("down_arrow","up")
            elseif pitch < -20 then
                myo.keyboard("down_arrow", "down")
            end
            
            -- yaw controls left-right panning 
            yaw = 57.3 * myo.getYaw()
            difference = yaw - initialYaw
            
            -- calculate if measurement went past modulus point
            if difference > 180 then
                difference = difference - 360
            elseif difference < -180 then
                difference = difference + 360
            end
            
            -- left-right panning conditions
            if difference > 20 then
                myo.keyboard("left_arrow", "down")
            elseif difference < -20 then
                myo.keyboard("right_arrow", "down")
            elseif difference < 20 and pitch > -20 then
                myo.keyboard("left_arrow", "up")
                myo.keyboard("right_arrow","up")
            end
            timerCounter2 = 0
        end

        timerCounter2 = timerCounter2 + 1
        
        -- debugging code
        if timerCounter == 0 then
            test = test + 1
            if test == 100 then
                test = 0
                myo.debug(myo.getPitch())
                myo.debug(myo.getYaw())
                myo.debug(myo.getXDirection())
            end
        end
    end
end

function onForegroundWindowChange(app, title)
    return true
end