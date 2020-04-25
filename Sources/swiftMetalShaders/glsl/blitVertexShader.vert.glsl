#version 450

layout (location = 0) in vec4 inPosition;

void
main(void)
{
    gl_Position = inPosition;
}

