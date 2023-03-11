local robox = require(settings.get("require.api_path") .. "turtle.robox").configure()




for i = 1, 15, 1
do
    robox.select(i)
    local slot = robox.getItemDetail()
    if( slot ~= nil and slot.name ~= "minecraft:bone_meal")
    then
        while robox.getItemDetail() ~= nil 
        do
            if(robox.dropDown() == false)
            then
                os.sleep(3)
                robox.select(16)
                robox.digDown()
                robox.placeDown()
                robox.select(i)
            end
        end
    end
end