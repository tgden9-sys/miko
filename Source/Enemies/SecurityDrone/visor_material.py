"""Blend red alert emission into the source model's actual dark visor faces."""

def install(body):
    material = body.data.materials[0].copy()
    material.name = 'Drone_Visor_State'
    body.data.materials[0] = material
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get('Principled BSDF')
    original = next(link.from_socket for link in bsdf.inputs['Base Color'].links)

    def math(operation, left, right=None, value=None):
        node = nodes.new('ShaderNodeMath')
        node.operation = operation
        links.new(left, node.inputs[0])
        if right is not None:
            links.new(right, node.inputs[1])
        elif value is not None:
            node.inputs[1].default_value = value
        return node.outputs[0]

    position = nodes.new('ShaderNodeNewGeometry')
    xyz = nodes.new('ShaderNodeSeparateXYZ')
    links.new(position.outputs['Position'], xyz.inputs[0])
    abs_x = nodes.new('ShaderNodeMath')
    abs_x.operation = 'ABSOLUTE'
    links.new(xyz.outputs['X'], abs_x.inputs[0])
    mask = math('LESS_THAN', abs_x.outputs[0], value=0.235)
    mask = math('MULTIPLY', mask, math('LESS_THAN', xyz.outputs['Y'], value=-0.175))
    mask = math('MULTIPLY', mask, math('GREATER_THAN', xyz.outputs['Z'], value=0.095))
    mask = math('MULTIPLY', mask, math('LESS_THAN', xyz.outputs['Z'], value=0.185))
    gray = nodes.new('ShaderNodeRGBToBW')
    links.new(original, gray.inputs[0])
    mask = math('MULTIPLY', mask, math('LESS_THAN', gray.outputs[0], value=0.37))

    alert = nodes.new('ShaderNodeValue')
    alert.name = 'Visor_Alert_Amount'
    alert.label = 'Visor alert 0 to 1'
    alert.outputs[0].default_value = 0.0
    mask = math('MULTIPLY', mask, alert.outputs[0])
    mix = nodes.new('ShaderNodeMixRGB')
    mix.blend_type = 'MIX'
    links.new(math('MULTIPLY', mask, value=0.65), mix.inputs[0])
    links.new(original, mix.inputs[1])
    mix.inputs[2].default_value = (0.40, 0.004, 0.008, 1.0)
    links.new(mix.outputs[0], bsdf.inputs['Base Color'])
    bsdf.inputs['Emission Color'].default_value = (0.80, 0.004, 0.01, 1.0)
    links.new(math('MULTIPLY', mask, value=1.2), bsdf.inputs['Emission Strength'])
    return alert
