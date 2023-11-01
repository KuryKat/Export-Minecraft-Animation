--[[
 *     EMA (Easy Minecraft Animation) - Aseprite Script
 *     Copyright (C) 2023 KuryKat
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 --]]

if (app.sprite == nil) then
    print(
        "[ERROR] This operation can only be performed when editing a sprite. Please ensure you have a sprite open and focused."
    )
    return
end

local dlg = Dialog({ title = "EMA - Export Minecraft Animation" })

function Export(fullPath)
    app.command.ExportSpriteSheet({
        ui = false,
        askOverwrite = true,
        type = SpriteSheetType.VERTICAL,
        columns = app.sprite.height * #Frames,
        rows = 1,
        width = app.sprite.width,
        height = 0,
        bestFit = false,
        textureFilename = fullPath,
        dataFilename = "",
        dataFormat = SpriteSheetDataFormat.JSON_HASH,
        filenameFormat = "png",
        borderPadding = 0,
        shapePadding = 0,
        innerPadding = 0,
        trimSprite = false,
        trim = false,
        trimByGrid = false,
        extrude = false,
        ignoreEmpty = false,
        mergeDuplicates = false,
        openGenerated = false,
        layer = "",
        tag = "",
        splitLayers = false,
        splitTags = false,
        listLayers = true,
        listTags = true,
        listSlices = true,
    })
end

function GetMeta(interpolate_frames, use_individual_framerate)
    local mcmeta_table = {
        animation = {
            interpolate = interpolate_frames
        }
    }

    if (use_individual_framerate) then
        mcmeta_table.animation.frames = {}
        for i = 1, #Frames do
            table.insert(
                mcmeta_table.animation.frames,
                {
                    index = tostring(Frames[i].frameNumber - 1),
                    time = tostring(math.floor(Frames[i].duration * 20))
                }
            )
        end
    else
        mcmeta_table.animation.frametime = Frames[1].duration * 20
    end

    return json.encode(mcmeta_table)
end

function Execute(name, path, interpolate_frames, use_individual_framerate)
    print("[INFO] Starting Execution...")
    local folder_path = app.fs.normalizePath(path)

    if not (app.fs.isDirectory(folder_path)) then
        print("[ERROR] The provided path \"" ..
            folder_path ..
            "\" is not a valid folder. Please ensure that the directories exist and that the path points to a folder.")
        return
    end

    local file_name = app.fs.fileTitle(name) .. ".png"
    local file_path = app.fs.joinPath(folder_path, file_name)

    print("[INFO] Exporting Texture File...")
    Export(file_path)

    local mcmetafile_name = file_name .. ".mcmeta"
    local mcmetafile_path = app.fs.joinPath(folder_path, mcmetafile_name)
    local mcmetafile = io.open(mcmetafile_path, "w")
    if mcmetafile == nil then
        print("[ERROR] Failed to write the Metadata file to the following path: \"" ..
            mcmetafile_path .. "\". Please check if the directory exist.")
    else
        local mcmeta = GetMeta(interpolate_frames, use_individual_framerate)
        print("[INFO] Exporting Metadata File...")
        mcmetafile:write(mcmeta)
        print("[INFO] Successfully exported files \"" ..
            file_name ..
            "\" and \"" ..
            mcmetafile_name .. "\" to the following directory: \"" .. folder_path .. "\".")
        mcmetafile:close()
    end
end

Frames = app.sprite.frames

dlg
    :entry({
        id = "name",
        label = "Texture Name",
        text = app.fs.fileTitle(app.sprite.filename),
        focus = true
    })
    :entry({
        id = "folder_path",
        label = "Folder Path",
        text = app.fs.filePath(app.sprite.filename),
        focus = false
    })
    :check({
        id = "interpolate_frames",
        label = "Interpolate Frames",
        selected = false,
        focus = false,
        hexpand = false
    })
    :check({
        id = "use_individual_framerate",
        label = "Use Individual Frametime",
        selected = false,
        focus = false,
        hexpand = false
    })
    :button({
        id = "export_animation",
        text = "Export Animation",
        selected = false,
        focus = false,
        onclick = function()
            dlg:close()
            Execute(
                dlg.data.name,
                dlg.data.folder_path,
                dlg.data.interpolate_frames,
                dlg.data.use_individual_framerate
            )
        end,
    })
    :button({
        id = "cancel",
        text = "Cancel",
        selected = false,
        focus = false,
        onclick = function() dlg:close() end
    })
    :show()
