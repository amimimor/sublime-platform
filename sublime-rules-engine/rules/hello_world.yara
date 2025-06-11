rule HelloWorld
{
    strings:
        $a = "hello world"

    condition:
        $a
}