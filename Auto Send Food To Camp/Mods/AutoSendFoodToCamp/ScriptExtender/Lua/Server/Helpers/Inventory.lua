-- Adapted from FocusBG3: https://www.nexusmods.com/baldursgate3/mods/5972

local CAMP_SUPPLY_SACK_TEMPLATE_ID = 'efcb70b7-868b-4214-968a-e23f6ad586bc'

---@param object any
---@return EntityHandle|nil
function GetHolder(object)
  local entity = GetEntity(object)
  if entity ~= nil and entity.InventoryMember ~= nil then
    return entity.InventoryMember.Inventory.InventoryIsOwned.Owner
  end

  return nil
end

---@param object any
---@return EntityHandle | nil
function GetEntity(object)
  return GetCharacter(object) or GetItem(object)
end

function IsCharacter(object)
  local objectType = type(object)
  if objectType == "userdata" then
    local mt = getmetatable(object)
    local userdataType = Ext.Types.GetObjectType(object)
    if mt == "EntityProxy" and object.IsCharacter ~= nil then
      return true
    elseif userdataType == "esv::CharacterComponent"
        or userdataType == "ecl::CharacterComponent"
        or userdataType == "esv::Character"
        or userdataType == "ecl::Character" then
      return true
    end
  elseif objectType == "string" or objectType == "number" then
    local entity = Ext.Entity.Get(object)
    return entity ~= nil and entity.IsCharacter ~= nil
  end
  return false
end

function GetCharacter(object)
  local objectType = type(object)
  if objectType == "userdata" then
    local mt = getmetatable(object)
    local userdataType = Ext.Types.GetObjectType(object)
    if mt == "EntityProxy" and object.IsCharacter ~= nil then
      return object
    elseif userdataType == "esv::CharacterComponent" or userdataType == "ecl::CharacterComponent" then
      return object.Character.MyHandle
    elseif userdataType == "esv::Character" or userdataType == "ecl::Character" then
      return object.MyHandle
    end
  elseif objectType == "string" or objectType == "number" then
    local entity = Ext.Entity.Get(object)
    if entity ~= nil and IsCharacter(entity) then
      return entity
    end
  end
end

function GetCharacterObject(object)
  local entity = GetCharacter(object)
  if entity ~= nil then
    return entity.ServerCharacter
  end
end

function IsItem(object)
  local objectType = type(object)
  if objectType == "userdata" then
    local mt = getmetatable(object)
    local userdataType = Ext.Types.GetObjectType(object)
    if mt == "EntityProxy" and object.IsItem ~= nil then
      return true
    elseif userdataType == "esv::ItemComponent"
        or userdataType == "ecl::ItemComponent"
        or userdataType == "esv::Item"
        or userdataType == "ecl::Item" then
      return true
    end
  elseif objectType == "string" or objectType == "number" then
    local entity = Ext.Entity.Get(object)
    return entity ~= nil and entity.IsItem ~= nil
  end
  return false
end

function GetItem(object)
  local objectType = type(object)
  if objectType == "userdata" then
    local userdataType = Ext.Types.GetObjectType(object)
    local mt = getmetatable(object)
    if mt == "EntityProxy" and object.IsItem ~= nil then
      return object
    elseif userdataType == "esv::ItemComponent" or userdataType == "ecl::ItemComponent" then
      return object.Item.MyHandle
    elseif userdataType == "esv::Item" or userdataType == "ecl::Item" then
      return object.MyHandle
    elseif userdataType == "CDivinityStats_Item" then
      return object.GameObject
    end
  elseif objectType == "string" or objectType == "number" then
    local entity = Ext.Entity.Get(object)
    if entity ~= nil and IsItem(object) then
      return entity
    end
  end
end

function GetItemObject(object)
  local entity = GetItem(object)
  if entity ~= nil then
    return entity.ServerItem
  end
end

function GetObject(object)
  return GetCharacterObject(object) or GetItemObject(object)
end

--- Returns a name-sorted array of all items in an object's inventory
---@param object any
---@param primaryOnly? boolean
---@param shallow? boolean
-- -@return {Entity:EntityHandle, Guid:Guid, Name:string, TemplateId:string, TemplateName:string}[]
function GetInventory(object, primaryOnly, shallow)
  local items = {}
  local entity = GetEntity(object)
  if entity ~= nil then
    local inventory = entity.InventoryOwner
    if inventory ~= nil then
      local inventories = primaryOnly and 1 or #inventory.Inventories
      for i = 1, inventories do
        for _, itemObj in pairs(inventory.Inventories[i].InventoryContainer.Items) do
          local item = itemObj.Item
          local info = {
            Entity = item,
            Guid = item.Uuid.EntityUuid,
            Name = Ext.Loca.GetTranslatedString(item.DisplayName.NameKey.Handle.Handle),
            TemplateId = "",
            TemplateName = ""
          }

          local esvObject = GetObject(item)
          if esvObject ~= nil then
            info.TemplateId = esvObject.Template.Id
            info.TemplateName = esvObject.Template.Name
          end

          table.insert(items, info)

          if not shallow and item.InventoryOwner ~= nil then
            for _, itemInfo in ipairs(GetInventory(item)) do
              table.insert(items, itemInfo)
            end
          end
        end
      end
    end
  end

  table.sort(items, function(a, b) return a.Name < b.Name end)
  return items
end

function GetCampChestInventory()
  local campChest = Osi.DB_Camp_UserCampChest:Get(nil, nil)[1][2]
  return GetInventory(campChest, true, true)
end

--- Checks if an inventory contains a supply sack.
---@param inventoryItems any The first
---@return any | nil - The first supply sack object, or nil if not found.
function TryToGetCampChestSupplyPack(inventoryItems)
  for _, item in ipairs(inventoryItems) do
    if item.TemplateId == CAMP_SUPPLY_SACK_TEMPLATE_ID then
      return item
    end
  end

  return nil
end

function CheckForCampChestSupplySack()
  return TryToGetCampChestSupplyPack(GetCampChestInventory())
end

function AddSupplySackToCampChest()
  local campChest = Osi.DB_Camp_UserCampChest:Get(nil, nil)[1][2]
  Utils.DebugPrint(1, "Adding supply sack to camp chest: " .. campChest)
  Osi.TemplateAddTo(CAMP_SUPPLY_SACK_TEMPLATE_ID, campChest, 1)
end

function AddSupplySackToCampChestIfMissing()
  if CheckForCampChestSupplySack() ~= nil then
    Utils.DebugPrint(3, "Supply sack found in camp chest.")
  else
    Utils.DebugPrint(3, "Supply sack not found in camp chest. Creating one.")
    AddSupplySackToCampChest()
  end
end

function GetCampChestSupplySack()
  return CheckForCampChestSupplySack()
end
