for i, force in pairs(game.forces) do 
  force.reset_recipes()
  force.reset_technologies()
  
  if force.technologies["circuit-network-2"].researched then
    force.recipes["item-sensor"].enabled = true
  else
    force.recipes["item-sensor"].enabled = false
  end
end
