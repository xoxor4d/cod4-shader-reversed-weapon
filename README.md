# Partially reversed cod4 weapon shaders
Techniques / Shaders in this repo currently cover the following lighting-states:
```cpp
unlit  
lit  
lit sun  
lit sun shadow  
lit spot  
lit spot shadow  
light omni
```

It is worth noting that techniques using shadow-mapping require HSM (hardware shadow-mapping) to be supported by the GPU. The GPU also needs to support ShaderModel 3 + the client needs to use it aswell (r_rendererPreference / r_rendererInUse). 

If one of the above requirements isn't fulfilled or you find yourself in a lighting situation thats not covered by this repo, stock cod4 techniques / shaders will be used (non-hsm variants, stock hsm variants or stock ShaderModel 2 techsets located in `techsets/sm2`).
<br/><br/>

# Engine Background (SM / HSM)
Most, if not all cod4 weapons use the __l_sm_r0c0s0__ techset (-light, -shadowmap, -reflection-color-specular ). If cod4 detects that your GPU supports HSM, the engine will remap `l_sm_` to `l_hsm_`. Since this repo is about models (weapon models in particular) the engine will also add the `mc_` prefix. That means that the main techset for all techniques featured in this repo is `mc_l_hsm_r0c0s0`. 

Because I don't want to modify stock techsets, techniques and shaders, I've changed `r0c0s0` to `xo_rcs` (note: both are 6 chars long giving you the ability to replace `l_sm_r0c0s0` with `l_sm_xo_rcs` in all kinds of materials using the `l_sm_r0c0s0` techset).
<br/><br/>

# Compiling
Drop included files into `cod4/raw/` and compile shaders with https://xoxor4d.github.io/projects/cod4-compileTools/ or refer to the following tutorial section https://xoxor4d.github.io/tutorials/hlsl-intro/#compiling  

Please note that you need the `shader_vars.h` header file in `shader_bin/shader_src` that comes with my compileTools or the shader package
<a href="https://drive.google.com/open?id=14xNhEJtRVFaYG3rQZOV7fvjmd2R7CwUP">v1.1_hlsl_xoxor4d.zip</a> and is therefore not included here.
<br/><br/>

# Modifications / Additions
If you want to change the used techniques or replace stock ones, you only need to do so in `mc_l_hsm_xo_rcs.techset`.  
If you want to add "effects" to your gun, you'll need to add that effect to each and every technique / shader so its consistent accross different lighting states. You could also use different effects for different lighting states if you wish.  

I've included a Visual Studio solution as I like using Tim G. Jones <a href="https://marketplace.visualstudio.com/items?itemName=TimGJones.HLSLToolsforVisualStudio">HLSL Tools for Visual Studio</a>
<br/><br/>

# Techset Lighting States
```cpp
"fakelight normal"              // radiant fakelight
"fakelight view":               // radiant fakelight
"case texture":                 // radiant only  
"shaded wireframe":             // radiant only  
"solid wireframe":              // radiant only  
"debug bumpmap":                // r_debugShader 1-4  
"debug bumpmap instanced":      // ^ grouped objects like grass
"depth prepass":                
"build shadowmap depth":  
"build shadowmap color":  
"build floatz":  
"unlit":                        // fullbright  
"lit":                          // sm_enable 0 + not in sun || sm_enable 1 + not in sun  
"lit sun":                      // sm_enable 0 + in sun  
"lit sun shadow":               // sm_enable 1 + in sun  
"lit spot":                     // sm_enable 0 :: spotlight / dlight  
"lit spot shadow":              // sm_enable 1 :: spotlight / dlight  
"lit omni":                     // no clue  
"lit omni shadow":              // no clue  
"lit instanced":                // prob. grouped objects like grass / trees
"lit instanced sun":            // ^
"lit instanced sun shadow":     // ^
"lit instanced spot":           // ^
"lit instanced spot shadow":    // ^
"lit instanced omni":           // ^
"lit instanced omni shadow":    // ^
"light omni":                   // fx omni lights  
"light spot":                   // fx spot lights  
"light spot shadow":            // fx shadow-casting spot lights  
"sunlight preview":             // radiant only?  
"shadowcookie caster":          // shadow caster
"shadowcookie receiver":        // shadow receiver
```
