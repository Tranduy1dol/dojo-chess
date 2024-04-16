use starknet::ContractAddress;

#[derive(Model, Drop, Serde, Debug)]
struct Player {
    #[key]
    game_id: u32,
    #[key]
    address: ContractAddress,
    color: Color
}

#[derive(Serde, Drop, Copy, PartialEq, Introspect, Debug)]
enum Color {
    White,
    Black,
    None,
}

trait PlayerTrait {
    fn is_not_my_piece(self: @Player, piece_color: Color) -> bool;
}

impl PalyerImpl of PlayerTrait {
    fn is_not_my_piece(self: @Player, piece_color: Color) -> bool {
        *self.color != piece_color
    }
}