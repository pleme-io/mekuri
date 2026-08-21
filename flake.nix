{
  description = "Mekuri (めくり) — zero-dependency page-turn decision: is a frame owed, and the permission to draw it";

  inputs.substrate.url = "github:pleme-io/substrate";

  outputs = { substrate, ... }: substrate.rust.library {
    src = ./.;
  };
}
