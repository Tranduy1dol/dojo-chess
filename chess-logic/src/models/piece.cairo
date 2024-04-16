use chess::models::player::Color;
use starknet::ContractAddress;

#[derive(Model, Drop, Serde, Copy)]
struct Piece {
    #[key]
    game_id: u32,
    #[key]
    position: Vec2,
    color: Color,
    piece_type: PieceType,
}

#[derive(Copy, Drop, Serde, Introspect, Eq, PartialEq, Debug)]
struct Vec2 {
    x: u32,
    y: u32
}

#[derive(Serde, Drop, Copy, PartialEq, Introspect)]
enum PieceType {
    None,
    Pawn,
    Knight,
    Bishop,
    Rook,
    Queen,
    King,
}

#[derive(Serde, Drop, Copy, Model, Debug)]
struct MoveResult {
    #[key]
    game_id: u32,
    #[key]
    curr_position: Vec2,
    #[key]
    next_position: Vec2,
    result: bool,
}

#[derive(Serde, Drop, Copy, Debug, Display)]
trait PieceTrait {
    fn is_out_of_board(next_position: Vec2) -> bool;
    fn is_right_piece_move(self: @Piece, next_position: Vec2) -> bool;
    fn get_distance(curr_position: Vec2, next_position: Vec2) -> u32;
    fn get_direction(curr_position: Vec2, next_position: Vec2) -> (u32, u32, u32, u32);
    fn diff(a: u32, b: u32) -> u32;
}

impl PieceImpl of PieceTrait {
    fn is_out_of_board(next_position: Vec2) -> bool {
        next_position.x > 7 || next_position.y > 7 || next_position.x < 0 || next_position.y < 0
    }

    fn is_right_piece_move(self: @Piece, next_position: Vec2) -> bool {
        let n_x = next_position.x;
        let n_y = next_position.y;
        if (n_x == *self.position.x && n_y == *self.position.y) { return false; }
        match self.piece_type {
            PieceType::Pawn => {
                match self.color {
                    Color::White => {
                        (n_x == *self.position.x && n_y == *self.position.y + 1)
                            || (n_x == *self.position.x && n_y == *self.position.y + 2)
                            || (n_x == *self.position.x + 1 && n_y == *self.position.y + 1)
                            || (n_x == *self.position.x - 1 && n_y == *self.position.y + 1)
                    },
                    Color::Black => {
                        (n_x == *self.position.x && n_y == *self.position.y - 1)
                            || (n_x == *self.position.x && n_y == *self.position.y - 2)
                            || (n_x == *self.position.x + 1 && n_y == *self.position.y - 1)
                            || (n_x == *self.position.x - 1 && n_y == *self.position.y - 1)
                    },
                    Color::None => panic(array!['Should not move empty piece']),
                }
            },
            PieceType::Knight => { 
                (PieceTrait::diff(*self.position.x, n_x) == 2 && PieceTrait::diff(*self.position.y, n_y) == 1)
                || (PieceTrait::diff(*self.position.x, n_x) == 1 && PieceTrait::diff(*self.position.y, n_y) == 2)
             },
            PieceType::Bishop => {
                PieceTrait::diff(*self.position.x, n_x) == PieceTrait::diff(*self.position.y, n_y)
            },
            PieceType::Rook => {
                (n_x == *self.position.x || n_y != *self.position.y)
                || (n_x != *self.position.x || n_y == *self.position.y)
            },
            PieceType::Queen => {
                (n_x == *self.position.x) || (n_y == *self.position.y)
                || (PieceTrait::diff(*self.position.x, n_x) == PieceTrait::diff(*self.position.y, n_y))
            },
            PieceType::King => {
                (PieceTrait::diff(*self.position.x, n_x) <= 1 && PieceTrait::diff(*self.position.y, n_y) <= 1)
            },
            PieceType::None => panic(array!['Should not move empty piece']),
        }
    }

    fn diff(a: u32, b: u32) -> u32 {
         if a < b { return b - a; }
         return a - b;
    }

    fn get_distance(curr_position: Vec2, next_position: Vec2) -> u32 {
        let x: u32 = PieceTrait::diff(curr_position.x, next_position.x);
        let y: u32 = PieceTrait::diff(curr_position.y, next_position.y);
        if x > y {
            return x;
        } else {
            return y;
        }
    }

    //top, right, down, left
    fn get_direction(curr_position: Vec2, next_position: Vec2) -> (u32, u32, u32, u32) {
        let curr_x = curr_position.x;
        let curr_y = curr_position.y;
        let next_x = next_position.x;
        let next_y = next_position.y;

        let mut top: u32 = 0;
        let mut right: u32 = 0;
        let mut down: u32 = 0;
        let mut left: u32 = 0;

        if next_x > curr_x {
            right = 1;
        }
        if next_x < curr_x {
            left = 1;
        }
        if next_y > curr_y {
            top = 1;
        }
        if next_y < curr_y {
            down = 1;
        }

        return (top, right, down, left);
    }
}

#[cfg(test)]
mod test {
    use super::PieceTrait;
    use chess::models::piece::Vec2;

    #[test]
    fn test_diff() {
        assert!(PieceTrait::diff(2, 1) == 1, "Should be 1");
        assert!(PieceTrait::diff(1, 2) == 1, "Should be 1");
    }

    #[test]
    fn test_direction() {
        let mut test_curr = Vec2 {x: 0, y: 0};
        let mut test_next = Vec2 {x: 1, y: 1};
        let (a, b, c, d): (u32, u32, u32, u32) = PieceTrait::get_direction(test_curr, test_next);
        assert!((a, b, c, d) == (1, 1, 0, 0), "Wrong direction");

        let mut test_curr = Vec2 {x: 2, y: 2};
        let mut test_next = Vec2 {x: 1, y: 1};
        let (a, b, c, d): (u32, u32, u32, u32) = PieceTrait::get_direction(test_curr, test_next);
        assert!((a, b, c, d) == (0, 0, 1, 1), "Wrong direction");
    }

    #[test]
    fn test_distance() {
        let mut test_curr = Vec2 {x: 0, y: 0};
        let mut test_next = Vec2 {x: 1, y: 2};
        assert!(PieceTrait::get_distance(test_curr, test_next) == 2, "Wrong distance");
    }
}

