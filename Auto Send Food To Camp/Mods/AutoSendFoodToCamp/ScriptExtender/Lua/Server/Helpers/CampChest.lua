local CAMP_SUPPLY_SACK_TEMPLATE_ID = 'efcb70b7-868b-4214-968a-e23f6ad586bc'

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
  return TryToGetCampChestSupplyPack(VCHelpers.Inventory:GetCampChestInventory(true))
end

function AddSupplySackToCampChest()
  local campChest = Osi.DB_Camp_UserCampChest:Get(nil, nil)[1][2]
  ASFTCPrint(1, "Adding supply sack to camp chest: " .. campChest)
  Osi.TemplateAddTo(CAMP_SUPPLY_SACK_TEMPLATE_ID, campChest, 1)
end

function AddSupplySackToCampChestIfMissing()
  if CheckForCampChestSupplySack() ~= nil then
    ASFTCPrint(3, "Supply sack found in camp chest.")
  else
    ASFTCPrint(3, "Supply sack not found in camp chest. Creating one.")
    AddSupplySackToCampChest()
  end
end
