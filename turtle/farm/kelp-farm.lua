local max_length = 6
local max_width = 6

turtle.refuel()
turtle.dig()
turtle.forward(1)

for width = 1, max_width+1, 1
do
    for length = 1, max_length, 1
    do
        turtle.dig()
        turtle.forward()
    end
    
    if(width == max_width+1)
    then
        --release all kelp in inventory
        for i = 2, 16, 1
        do
            turtle.select(i)
            turtle.dropUp()
        end
        --return home
        if(width %2 == 1)
        then
            turtle.turnRight()
            for i = 1, max_width, 1
            do
                turtle.dig()
                turtle.forward()
            end
            turtle.turnRight()
            for i = 1, max_length+1, 1
            do
                turtle.dig()
                turtle.forward()
            end
            turtle.turnRight()
            turtle.turnRight()
        else
            turtle.turnLeft()
            for i = 1, max_width, 1
            do
                turtle.dig()
                turtle.forward()
            end
            turtle.turnLeft()
            turtle.back()
        end
        return 
    end
    if(width % 2 == 1)
    then
        turtle.turnLeft()
        turtle.dig()
        turtle.forward()
        turtle.turnLeft()
    else
        turtle.turnRight()
        turtle.dig()
        turtle.forward()
        turtle.turnRight()
    end
end 
