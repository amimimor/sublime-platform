rule hello_world
{
    strings:
        $a = "hello world"

    condition:
        $a
} 