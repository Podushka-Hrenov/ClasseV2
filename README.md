# ClasseV2 (Alpha)

ClasseV2 is an improved version of Classe that is under development. It will be distinguished by the performance, security, and convenience of modern type detection

Example of ClasseV2

```luau
--!strict

local Gun = Classe.meta{ }

type Self = Classe.Self<typeof(Gun)>

function Gun.construct(self)
  self.ammo = 10
end

function Gun.shot(self: Self)
  self.ammo -= 10 -- OK!
  print("boom!")
end

return Classe.build(Gun)
```
