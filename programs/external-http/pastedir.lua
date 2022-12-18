--imports
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local function printUsage()
    print("A program for getting and posting single json text files that represent directories and all of their contents")
    print("This is useful if you dont want to create a single pastebin for multiple files")
    print("Usage:")
    print("pastedir encode <directory-name> [target-file]")
    print("-- encodes the directory/file and writes it to a target file with the preferred suffix .pastedir.txt")
    print("pastedir decode <encoded-file-path> [target-directory]")
    print("-- decodes an encoded pastedir.txt file and writes it to the optional target directory")
    print("pastedir put <directory-name>")
    print("-- encodes the directory/file and uploads the encoded file up to pastebin")
    print("-- returns pastebin link")
    print("pastedir get <pastebin-code> [target-directory]")
    print("--retrieves a pastedir file given the pastebin code and decodes the file and writes the directory and file structure to the optional target directory")
end

local function resolveAbsoluteAddress(path)
    return "/" .. shell.resolve(path)
end

local function encode_recursively(path)
    local node = fs.attributes(path)
    node.name = fs.getName(path)
    
    if(node.isDir)
    then
        node.data = {}
        local dir_contents = fs.list(path)
        for key, element_name in pairs(dir_contents)
        do
            local element_path = path .. "/" .. element_name
            if(fs.exists(element_path))
            then
                node.data[key] = encode_recursively(element_path)
            else
                error("error resolving an element in a directory at " .. element_path, 2)
            end
        end
    else
        --just a file
        local file = fs.open(path, "r")
        node.data = file.readAll()
        file.close()
    end
    return node
end

local function command_encode(path, target)
    --encode directory structure into a text file 
    local json = encode_recursively(path)
    local jsonString = textutils.serialize(json)

    local file, message = fs.open(target, "w")
    if(file == nil) 
    then
        error("Unable to create the file: " .. target .. " due to " .. message)
    end
    file.write(jsonString)
    file.close()
end

local function command_put(path)
    local tempname = "/.temp/" .. fs.getName(path) .. ".pastedir.txt"
    command_encode(path, tempname)

    shell.execute("pastebin", "put", tempname)

    fs.delete(tempname)
end

local function writeFile(path, json)
    local file, message = fs.open(path, "w")
    if(file == nil)
    then
        error("failed writing " .. path .. " due to " .. message)
    end

    file.write(json.data)
    --TODO other meta data?

    file.close()
end

local function writeDir(path, json)
    if(fs.exists(path) ~= false)
    then
        fs.makeDir(path)
    end

    local dir_contents = json.data
    --element can be file or dir 
    for key, element in pairs(dir_contents)
    do
        local element_path = resolveAbsoluteAddress(path .. "/" .. element.name)
        if(element.isDir)
        then
            --create directory if needed
            writeDir(element_path, element)
        else
            --overwrite file if it exists
            writeFile(element_path, element)
        end
    end
end

local function findAvalibleName(path)
    --extract extention if it has one
    local index = string.find(path, '%.')
    local base_path = path
    local extention = ""
    if(index)
    then
        base_path = string.sub(path, 1, index - 1)
        extention = string.sub(path, index)
    end

    for i = 1, 99, 1 
    do
        local currentPath = base_path .. "--copy-" .. string.format("%02d",i) .. extention
        if(fs.exists(currentPath) ~= true)
        then
            return currentPath
        end
    end
    error("too many copies of " .. path, 3)
end

local function command_decode(path, target)
    local encoded_file = fs.open(path, "r")
    local jsonString = encoded_file.readAll()
    encoded_file.close()
    local json = textutils.unserialize(jsonString)

    if(target)
    then
        target = resolveAbsoluteAddress(target)
    else
        --default behavior when a target is not provided
        target = resolveAbsoluteAddress(json.name)
    end
    print(target)

    if(json.isDir)
    then
        --encoded file requests a dir for its root object
        if(not fs.exists(target))
        then
            fs.makeDir(target)
        end

        if(fs.isDir(target)) --it is a directory that exists (not a file)
        then
            if(fs.getName(target) == json.name)
            then
                --target is same as requested name, keep it "flat"
                writeDir(target, json)
            else
                --target is different from requested name, embed contents inside of target directory
                local inside_target = resolveAbsoluteAddress(target .. "/" .. json.name)
                writeDir(inside_target, json)
            end
        else
            --ERROR: requesting a dir, but there is a file with the same name
            error("cannot create a directory with the same name as an existing file: " .. target, 2)
        end
    else
        --encoded file only contains one file so just write a flat file 
        if(fs.isDir(target))
        then
            --ERROR: requesting a file, but there is a dir with the same name
            error("cannot create a file with the same name as an existing directory: " .. target, 2)
        elseif(fs.exists(target))
        then
            --existing file with that name, create a file in the format of filename--copy-1.extension
            writeFile(findAvalibleName(target), json)
        else
            --no existing file
            writeFile(target, json)
        end

    end
end

local function command_get(code, target)
    --download encoded file to a temp file first
    local tempname = "/.temp/get-" .. code .. ".pastedir.txt"
    shell.execute("pastebin", "get" , code, tempname)

    --decode file and put into target
    command_decode(tempname, target)

    fs.delete(tempname)
end

local function verifyPath(path)
    if(path == nil)
    then
        error("path required. See usage by typing pastedir --help", 2)
    end
    
    local path = resolveAbsoluteAddress(path)
    if(fs.exists(path) ~= true)
    then
        error("provided path(" .. path .. ") did not exists", 2)
    end

    return path
end

--process command
local command = arg[1]
if(command == nil)
then
    print("Please provide a command")
    printUsage()
elseif(command == "encode")
then
    local path = verifyPath(arg[2])
    local target = arg[3] or fs.getName(path) .. ".pastedir.txt"
    command_encode(path, resolveAbsoluteAddress(target))
elseif(command == "decode")
then
    local path = verifyPath(arg[2])
    local target = arg[3]
    command_decode(path, target)
elseif(command == "put")
then
    local path = verifyPath(arg[2])
    command_put(path)
elseif(command == "get")
then
    if(arg[2])
    then
        command_get(arg[2], arg[3])
    else
        print("please provide a pastebin code")
    end
elseif(command == "-h" or command == "--help")
then
    printUsage()
    return
else
    error("Command not supported: " .. command)
end