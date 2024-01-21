Food = {}

function IsFood(item)
  return Osi.ItemGetSupplyValue(item) > 0
end

function IsBeverage(item)
  return IsFood(item) and Osi.IsConsumable(item) == 1
end

return Food
