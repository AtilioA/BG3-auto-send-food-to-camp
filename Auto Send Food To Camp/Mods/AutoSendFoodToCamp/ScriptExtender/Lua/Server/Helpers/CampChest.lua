local CAMP_SUPPLY_SACK_TEMPLATE_ID = 'efcb70b7-868b-4214-968a-e23f6ad586bc'

---@class CampSupplySack
---@field Guid GUIDSTRING
---@field TemplateId GUIDSTRING

--- Finds the first supply sack in an inventory.
---@param inventoryItems CampSupplySack[] Inventory items to search.
---@return CampSupplySack|nil supplySack The first supply sack, if present.
function TryToGetCampChestSupplyPack(inventoryItems)
  for _, item in ipairs(inventoryItems) do
    if item.TemplateId == CAMP_SUPPLY_SACK_TEMPLATE_ID then
      return item
    end
  end

  return nil
end

--- Finds the supply sack in any camp chest.
---@return CampSupplySack|nil supplySack The camp chest supply sack, if present.
function CheckForCampChestSupplySack()
  for _, chestUUID in ipairs(VCHelpers.Camp:GetAllCampChestUUIDs()) do
    local supplySack = TryToGetCampChestSupplyPack(VCHelpers.Inventory:GetInventory(chestUUID, true, true))
    if supplySack ~= nil then
      return supplySack
    end
  end

  return nil
end

--- Adds a supply sack to the camp chest.
---@return nil
function AddSupplySackToCampChest()
  local campChest = Osi.DB_Camp_UserCampChest:Get(nil, nil)[1][2]
  ASFTCPrint(1, "Adding supply sack to camp chest: " .. campChest)
  Osi.TemplateAddTo(CAMP_SUPPLY_SACK_TEMPLATE_ID, campChest, 1)
end

--- Adds a supply sack to the camp chest when none exists.
---@return nil
function AddSupplySackToCampChestIfMissing()
  if CheckForCampChestSupplySack() ~= nil then
    ASFTCPrint(3, "Supply sack found in camp chest.")
  else
    ASFTCPrint(3, "Supply sack not found in camp chest. Creating one.")
    AddSupplySackToCampChest()
  end
end
