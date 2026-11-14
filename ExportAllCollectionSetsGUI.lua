local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'

local ExportCollectionSet = require 'ExportCollectionSet'
local Utils = require 'Utils'

local function showExportDialog()

	LrFunctionContext.callWithContext( "showExportDialog", function( context )
    local f = LrView.osFactory()
    local properties = LrBinding.makePropertyTable(context)

    LrTasks.startAsyncTask(
      function()
        local catalog = LrApplication.activeCatalog()
        local collectionSets = catalog:getChildCollectionSets()
        local items = {}

        for _, collectionSet in ipairs(collectionSets) do
          table.insert(items, collectionSet:getName())
        end

        properties.rootPath = Utils.getSavedRootPath()
        properties.exportSettingsPath = Utils.getSavedExportSettingsPath()
        properties.deleteUnmatchedFiles = false

        local contents = f:column {
          bind_to_object = properties,
          spacing = f:control_spacing(),
          f:static_text {
            title = "Pressing OK will export the following collection sets and all their contents to the selected path.",
            fill_horizontal = 1,
          },
          f:static_text {
            title = "Remember that this might take a while:",
            fill_horizontal = 1,
          },
          f:static_text {
            title = table.concat(items, "\n"),
            fill_horizontal = 1,
          },
          f:push_button {
            title = "Select Folder",
            action = function()
              local result = LrDialogs.runOpenPanel({
                canChooseDirectories = true,
                allowsMultipleSelection = false,
                canChooseFiles = false,
                initialDirectory = properties.rootPath,
              })
              if result then
                properties.rootPath = result[1]
                Utils.saveRootPath(result[1])
              end
            end,
          },
          f:static_text {
            title = LrView.bind('rootPath'),
            fill_horizontal = 1,
          },
          f:static_text {
            title = "A export settings file is optional, but not providing it will use Lightroom's defaults",
            fill_horizontal = 1,
          },
          f:push_button {
            title = "Select Export Settings",
            action = function()
              local result = LrDialogs.runOpenPanel({
                canChooseFiles = true,
                allowsMultipleSelection = false,
                canChooseDirectories = false,
                prompt = "Select ExportSettings.lrtemplate",
                initialDirectory = Utils.getExportSettingsDirectory(),
              })
              if result then
                local filePath = result[1]
                if filePath:sub(-11) ~= ".lrtemplate" then
                  LrDialogs.message("Error", "Please select a .lrtemplate file.", "critical")
                else
                  properties.exportSettingsPath = filePath
                  Utils.saveExportSettingsPath(filePath)
                end
              end
            end,
          },
          f:static_text {
            title = LrView.bind('exportSettingsPath'),
            fill_horizontal = 1,
          },
          f:checkbox {
            title = "Delete unmatched image/video files inside collection folders",
            value = LrView.bind('deleteUnmatchedFiles'),
          },
        }

        local result = LrDialogs.presentModalDialog({
          title = "Export All Collection Sets",
          contents = contents,
          enabled = LrView.bind("rootPath"),
        })

        if result == 'ok' then
          if properties.rootPath then
            local deleteUnmatchedFiles = properties.deleteUnmatchedFiles
            if deleteUnmatchedFiles and LrDialogs.confirm(
              "Delete unmatched export files?",
              "This permanently deletes image/video files in the exported collection folders that do not match a photo currently in those collections.",
              "Delete Files",
              "Cancel"
            ) ~= 'ok' then
              return
            end

            LrTasks.startAsyncTask(function()
              ExportCollectionSet.exportCollectionSets(
                collectionSets,
                properties.rootPath,
                properties.exportSettingsPath,
                deleteUnmatchedFiles
              )
            end)
          else
            LrDialogs.message("Error", "Please select a folder before proceeding.", "critical")
          end
        end
      end
    )
	end)
end

showExportDialog()
