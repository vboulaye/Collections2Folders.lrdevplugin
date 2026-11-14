local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'

local ExportCollection = require 'ExportCollection'
local Utils = require 'Utils'

local function exportCollectionSet(collectionSet, path, exportSettingsPath, deleteUnmatchedFiles)
  local exportSettings = Utils.loadExportSettings(exportSettingsPath)

  local childCollectionSets = collectionSet:getChildCollectionSets()
  local childCollections = collectionSet:getChildCollections()
  local outputPath = Utils.defineDestination(path, collectionSet:getName())

  for _, childCollectionSet in ipairs(childCollectionSets) do
    exportCollectionSet(childCollectionSet, outputPath, exportSettingsPath, deleteUnmatchedFiles)
  end

  for _, childCollection in ipairs(childCollections) do
    ExportCollection.exportCollection(childCollection, outputPath, exportSettings, deleteUnmatchedFiles)
  end
end

local function exportCollectionSets(collectionSets, path, exportSettingsPath, deleteUnmatchedFiles)
  for _, collectionSet in ipairs(collectionSets) do
    exportCollectionSet(collectionSet, path, exportSettingsPath, deleteUnmatchedFiles)
  end
end

return {
  exportCollectionSet = exportCollectionSet,
  exportCollectionSets = exportCollectionSets
}

