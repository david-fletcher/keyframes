-- MIT License

-- Copyright (c) 2021 David Fletcher

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

function init(plugin)
    print("Aseprite is initializing Keyframes")

    -----------------------------------
    -- "GLOBAL" VARIABLES
    -----------------------------------
    local isDialogOpen = false
    local tagMode = false

    -----------------------------------
    -- CREATE ERROR DIALOG
    -----------------------------------
    -- param: str - a string value that will be displayed to the user (usually an error message)
    -- param: dialog - the Dialog object (if any) that spawned this error message
    -- param: exit - a boolean value; 0 to keep dialog open, and 1 to close dialog
    -----------------------------------
    -- This function creates a simple dialog window that will alert the user of an error that occured.
    -- If you call this from a Dialog function, you can optionally close the dialog to end user interaction
    -- and prevent further errors (making the user try again).
    -----------------------------------
    local function create_error(str, dialog, exit)
        app.alert(str)
        if (exit == 1) then dialog:close() end
    end

    -----------------------------------
    -- CREATE CONFIRM DIALOG
    -----------------------------------
    -- param: str - a string value that will be displayed to the user (usually a question if they'd like to confirm an action)
    -- returns: true, if the user clicked "Confirm"; nil, if the user clicked "Cancel" or closed the dialog
    -----------------------------------
    -- This function creates a simple dialog window that will display a message, along with two buttons: "Cancel" and "Confirm".
    -- You can observe whether or not the user closed the dialog in this way:
    -- local confirmed = create_confirm("Would you like to continue?")
    -- if (not confirmed) then
    -- end
    -----------------------------------
    local function create_confirm(str)
        local confirm = Dialog("Confirm?")

        confirm:label {
            id="text",
            text=str
        }

        confirm:button {
            id="cancel",
            text="Cancel",
            onclick=function()
                confirm:close()
            end
        }

        confirm:button {
            id="confirm",
            text="Confirm",
            focus=true,
            onclick=function()
                confirm:close()
            end
        }

        -- show to grab centered coordinates
        confirm:show{ wait=true }

        return confirm.data.confirm
    end


    -----------------------------------
    -- MAIN LOGIC
    -----------------------------------
    local function getKeyframeLayer()
        for _,layer in ipairs(app.activeSprite.layers) do
            if (layer.name == "KEYFRAMES") then
                return layer
            end
        end
    
        local confirm = create_confirm("The KEYFRAMES layer could not be found. Would you like to have it added to your project?")
        if (confirm) then
            local layer = app.activeSprite:newLayer()
            layer.name = "KEYFRAMES"
            -- lock the frame so that the user has trouble editing it
            layer.isEditable = false
            return layer
        else
            return nil
        end
    end
    
    local function isCelFilled(layer, framenum)
        return layer:cel(framenum)
    end
    
    local function addKeyframe()
        local klayer = getKeyframeLayer()
        if (klayer == nil) then create_error("I could not add a keyframe because there is no KEYFRAMES layer.", nil, 0) return  end

        -- lock the frame so that the user has trouble editing it
        klayer.isEditable = false
        app.activeSprite:newCel(klayer, app.activeFrame)
        app.refresh()
    end
    
    local function deleteKeyframe()
        local klayer = getKeyframeLayer()
        if (klayer == nil) then create_error("I could not delete a keyframe because there is no KEYFRAMES layer.", nil, 0) return  end

        -- lock the frame so that the user has trouble editing it
        klayer.isEditable = false
        if (isCelFilled(klayer, app.activeFrame.frameNumber)) then
            app.activeSprite:deleteCel(klayer, app.activeFrame)
        end
        app.refresh()
    end
    
    local function gotoPrevious()
        local klayer = getKeyframeLayer()
        if (klayer == nil) then create_error("I could not go to the previous keyframe because there is no KEYFRAMES layer.", nil, 0) return  end

        -- lock the frame so that the user has trouble editing it
        klayer.isEditable = false

        -- bound is 1 if we are searching the whole sprite; and the starting tag frame if we are searching just within the tag
        local bound = 1
        if (app.activeTag ~= nil) and (tagMode) then
            bound = app.activeTag.fromFrame.frameNumber
        end

        -- loop just up to the bound
        for fnum=app.activeFrame.frameNumber-1,bound,-1 do
            if (isCelFilled(klayer, fnum)) then
                app.activeFrame = app.activeSprite.frames[fnum]
                app.refresh()
                return
            end
        end 
    end
    
    local function gotoNext()
        local klayer = getKeyframeLayer()
        if (klayer == nil) then create_error("I could not go to the next keyframe because there is no KEYFRAMES layer.", nil, 0) return  end

        -- lock the frame so that the user has trouble editing it
        klayer.isEditable = false

        -- bound is the last frame if we are searching the whole sprite; and the ending tag frame if we are searching just within the tag
        local bound = #app.activeSprite.frames
        if (app.activeTag ~= nil) and (tagMode) then
            bound = app.activeTag.toFrame.frameNumber
        end

        -- loop just up to the bound
        for fnum=app.activeFrame.frameNumber+1,bound do
            if (isCelFilled(klayer, fnum)) then
                app.activeFrame = app.activeSprite.frames[fnum]
                app.refresh()
                return
            end
        end
    end

    -----------------------------------
    -- HELPER DIALOG (OPTIONAL)
    -----------------------------------
    local function keyframeEditor()
        local dialog = Dialog{ title="Keyframes", onclose=function()
            isDialogOpen = false
            tagMode = false
            end
        }

        dialog:button {
            id="add",
            text="Add Keyframe",
            onclick=function()
                addKeyframe()
            end
        }

        dialog:button {
            id="delete",
            text="Delete Keyframe",
            onclick=function()
                deleteKeyframe()
            end
        }

        dialog:newrow()

        dialog:button {
            id="previous",
            text="Previous Keyframe",
            onclick=function()
                gotoPrevious()
            end
        }

        dialog:button {
            id="next",
            text="Next Keyframe",
            onclick=function()
                gotoNext()
            end
        }

        dialog:newrow()

        dialog:check {
            id="tag_mode",
            text="Stay within tag?",
            selected=false,
            onclick=function()
                tagMode = dialog.data.tag_mode
            end
        }

        isDialogOpen = true
        return dialog
    end

    -----------------------------------
    -- PLUGIN COMMANDS
    -----------------------------------
    -- A plugin command is simply a menu element that, when clicked, runs the function passed to onclick.
    -- In this file, we specify menu element definitions, but abstract away their implementations to different Lua scripts.
    -- This is done for organizational purposes, and to ease the iterative development of scripts. With this structure,
    -- we can develop the script file independently of the plugin definition, using Aseprite's scripting engine
    -- to run scripts as we build out our functionality, then wrap the finalized scripts in a plugin.
    -----------------------------------
    -- We use the parameter to init, plugin, to access the preferences table. This table will be saved on exit and restored
    -- upon re-entry, so that you can easily save any user-defined preferences you need to. You will notice that we use
    -- loadfile() to create a Lua chunk based on our script, and then pass the preferences table to the script as an argument.
    -- The script can modify that table, which will then be saved automagically by Aseprite's API.
    -----------------------------------
    plugin:newCommand {
        id="open_editor",
        title="Open Keyframe Editor",
        group="cel_frames",
        onclick=function()
            if (not isDialogOpen) then keyframeEditor():show{ wait=false } end
        end
    }

    plugin:newCommand {
        id="add_keyframe",
        title="Add Keyframe",
        group="cel_frames",
        onclick=function()
            addKeyframe()
        end
    }

    plugin:newCommand {
        id="delete_keyframe",
        title="Delete Keyframe",
        group="cel_frames",
        onclick=function()
            deleteKeyframe()
        end
    }

    plugin:newCommand {
        id="prev_keyframe",
        title="Go To Previous Keyframe",
        group="cel_frames",
        onclick=function()
            gotoPrevious()
        end
    }

    plugin:newCommand {
        id="next_keyframe",
        title="Go To Next Keyframe",
        group="cel_frames",
        onclick=function()
            gotoNext()
        end
    }
end
  
function exit(plugin)
    print("Aseprite is closing Keyframes")
end