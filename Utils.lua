local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrPrefs = import 'LrPrefs'

local preferences = LrPrefs.prefsForPlugin()

local function getExistingPreferencePath(key)
  local path = preferences[key]
  if type(path) == 'string' and LrFileUtils.exists(path) then
    return path
  end
  return nil
end

local function savePreferencePath(key, path)
  preferences[key] = path
end

local function childPath(path, components)
  for _, component in ipairs(components) do
    path = LrPathUtils.child(path, component)
  end
  return path
end

local function getDefaultExportSettingsDirectory()
  local appDataPath = LrPathUtils.getStandardFilePath('appData')
  if appDataPath then
    local windowsPath = childPath(appDataPath, {
      'Adobe', 'Lightroom', 'Export Presets', 'User Presets'
    })
    if LrFileUtils.exists(windowsPath) then
      return windowsPath
    end
  end

  local homePath = LrPathUtils.getStandardFilePath('home')
  if homePath then
    local macOSPath = childPath(homePath, {
      'Library', 'Application Support', 'Adobe', 'Lightroom', 'Export Presets', 'User Presets'
    })
    if LrFileUtils.exists(macOSPath) then
      return macOSPath
    end
  end

  return nil
end

local function getExportSettingsDirectory()
  local savedDirectory = getExistingPreferencePath('lastExportSettingsDirectory')
  if savedDirectory then
    return savedDirectory
  end

  local savedSettingsPath = getExistingPreferencePath('lastExportSettingsPath')
  if savedSettingsPath then
    local parentDirectory = LrPathUtils.parent(savedSettingsPath)
    if parentDirectory and LrFileUtils.exists(parentDirectory) then
      return parentDirectory
    end
  end

  return getDefaultExportSettingsDirectory()
end

local function createFolder(path)
  if not LrFileUtils.exists(path) then
    LrFileUtils.createDirectory(path)
  end
end

local function defineDestination(root, name)
  local outputPath = LrPathUtils.child(root, name)
  createFolder(outputPath)
  return outputPath
end

local function len(array)
  local i=0 for _ in pairs(array) do
    i = i + 1
  end
  return i
end

local function loadExportSettings(path)
  -- Use the default settings file if no path is provided
  if not path then
    return {}
  end

  -- Load the .lrtemplate file
  local file = io.open(path, "r")
  if file then
    local content = file:read("*all")
    file:close()

    -- Load and run the content as a Lua chunk
    local settingsFunc, err = loadstring(content .. "; return s")
    if err then
      print("Error loading settings: " .. err)
      return {}
    end

    if type(settingsFunc) == 'function' then
      local success, settingsTable = pcall(settingsFunc)
      if success and type(settingsTable) == 'table' and settingsTable.value then
        return settingsTable.value
      else
        print("Error running settings function: " .. tostring(settingsTable))
      end
    else
      print("Error: settingsFunc is not a function")
    end
  end

  return {}
end

return {
  createFolder = createFolder,
  defineDestination = defineDestination,
  len = len,
  loadExportSettings = loadExportSettings,
  getSavedRootPath = function()
    return getExistingPreferencePath('lastRootPath')
  end,
  getSavedExportSettingsPath = function()
    return getExistingPreferencePath('lastExportSettingsPath')
  end,
  saveRootPath = function(path)
    savePreferencePath('lastRootPath', path)
  end,
  saveExportSettingsPath = function(path)
    savePreferencePath('lastExportSettingsPath', path)
    savePreferencePath('lastExportSettingsDirectory', LrPathUtils.parent(path))
  end,
  getExportSettingsDirectory = getExportSettingsDirectory
}
