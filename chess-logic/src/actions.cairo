use starknet::ContractAddress;
use chess::models::piece::{Vec2, MoveResult};

#[dojo::interface]
trait IActions {
    fn get_move_result(game_id: u32, curr_position: Vec2, next_position: Vec2) -> MoveResult;
    fn is_legal_move(game_id: u32, curr_position: Vec2, next_position: Vec2, caller: ContractAddress);
    fn spawn(white_address: ContractAddress, black_address: ContractAddress) -> u32;
}

#[dojo::contract]
mod actions {
    use chess::models::player::{Player, Color, PlayerTrait};
    use chess::models::piece::{Piece, PieceType, PieceTrait, MoveResult};
    use chess::models::game::{Game, GameTurn, GameTurnTrait};
    use super::{ContractAddress, IActions, Vec2};

    #[abi(embed_v0)]
    impl IActionsImpl of IActions<ContractState> {
        fn is_legal_move(world: IWorldDispatcher,
                        game_id: u32,
                        curr_position: Vec2,
                        next_position: Vec2,
                        caller: ContractAddress) {

            let mut result: bool = true;
            //check if next position is not out of board
            if PieceTrait::is_out_of_board(next_position) {
                result = false;
            }
            assert!(!PieceTrait::is_out_of_board(next_position), "Should be inside board");

            //check if this piece move right
            let mut curr_piece = get!(world, (game_id, curr_position), (Piece));
            if !curr_piece.is_right_piece_move(next_position) {
                result = false;
            }
            assert!(curr_piece.is_right_piece_move(next_position), "Illegal move for type of piece");

            //check if next position have same color piece
            let mut next_position_piece = get!(world, (game_id, next_position), (Piece));
            let player = get!(world, (game_id, caller), (Player));
            if player.is_not_my_piece(next_position_piece.color) {
                result = false;
            }
            assert!(player.is_not_my_piece(next_position_piece.color)
                || next_position_piece.piece_type == PieceType::None,
                    "Already same color piece exist"
            );

            //check if this piece have a clear part from current position to next position
            if curr_piece.piece_type == PieceType::Pawn || curr_piece.piece_type == PieceType::Knight || curr_piece.piece_type == PieceType::King {
                result = true;
            }
            if curr_piece.piece_type == PieceType::Queen || curr_piece.piece_type == PieceType::Bishop || curr_piece.piece_type == PieceType::Rook {
                let mut d = PieceTrait::get_distance(curr_position, next_position);
                let (top, right, down, left) = PieceTrait::get_direction(curr_position, next_position);
                let mut i = 1;
                result = loop {
                    if i > d { break true; }

                    let mut x: u32 = 0;
                    if left != 0 { x = curr_position.x - i * left; }
                    if right != 0 { x = curr_position.x + i * right; }
                    if left == 0 && right == 0 { x = curr_position.x ;}

                    let mut y: u32 = 0;
                    if down != 0 { y = curr_position.y - i * down; }
                    if top != 0 { y = curr_position.y + i * top; }
                    if down == 0 && top == 0 { y = curr_position.y; }

                    let mut pos = Vec2 {x: x, y: y};
                    let mut piece = get!(world, (game_id, pos), (Piece));
                    if piece.piece_type != PieceType::None {
                        break false;
                    }
                    i += 1;
                }
            }

            //set result
            if result == true {
                // turn next position piece into current piece
                next_position_piece.piece_type = curr_piece.piece_type;
                next_position_piece.color = player.color;

                // make current_piece piece none
                curr_piece.piece_type = PieceType::None;
                curr_piece.color = Color::None;
                set!(world, (next_position_piece));
                set!(world, (curr_piece));

                // change turn
                let mut game_turn = get!(world, game_id, (GameTurn));
                game_turn.player_color = game_turn.next_turn();
                set!(world, (game_turn));
            }
            set!(world, MoveResult {
                game_id: game_id,
                curr_position: curr_position,
                next_position: next_position,
                result: result,
            });
        }

        fn get_move_result(world: IWorldDispatcher, game_id: u32, curr_position: Vec2, next_position: Vec2) -> MoveResult {
            let mut result = get!(world, (game_id, curr_position, next_position), (MoveResult));
            result
        }

        fn spawn(
            world: IWorldDispatcher,
            white_address: ContractAddress,
            black_address: ContractAddress
        ) -> u32 {
            let game_id: u32 = world.uuid();

            // set Players
            set!(
                world,
                (
                    Player { game_id, address: black_address, color: Color::Black },
                    Player { game_id, address: white_address, color: Color::White },
                )
            );

            // set Game and GameTurn
            set!(
                world,
                (
                    Game {
                        game_id, winner: Color::None, white: white_address, black: black_address
                    },
                    GameTurn { game_id, player_color: Color::White },
                )
            );

            // set white Pieces
            // set white Rook
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::White,
                    position: Vec2 { x: 0, y: 0 },
                    piece_type: PieceType::Rook
                })
            );
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::White,
                    position: Vec2 { x: 7, y: 0 },
                    piece_type: PieceType::Rook
                })
            );

            //set white pawn
            let mut i: u32 = 0;
            while i <= 7 {
                set!(
                     world,
                     (Piece {
                         game_id,
                         color: Color::White,
                         position: Vec2 { x: i, y: 1 },
                         piece_type: PieceType::Pawn
                    })
                );
                i += 1;
            };
 
            // set white Knight
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::White,
                    position: Vec2 { x: 1, y: 0 },
                    piece_type: PieceType::Knight
                })
            );
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::White,
                    position: Vec2 { x: 6, y: 0 },
                    piece_type: PieceType::Knight
                })
            );

            //set white Bishop
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::White,
                    position: Vec2 { x: 2, y: 0 },
                    piece_type: PieceType::Bishop,
                })
            );
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::White,
                    position: Vec2 { x: 5, y: 0 },
                    piece_type: PieceType::Bishop,
                })
            );

            //set white Queen
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::White,
                    position: Vec2 { x: 3, y: 0 },
                    piece_type: PieceType::Queen
                })
            );

            // set white King
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::White,
                    position: Vec2 { x: 4, y: 0 },
                    piece_type: PieceType::King
                })
            );

            // set black pieces
            // set black Rook
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::Black,
                    position: Vec2 { x: 0, y: 7 },
                    piece_type: PieceType::Rook
                })
            );
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::Black,
                    position: Vec2 { x: 7, y: 7 },
                    piece_type: PieceType::Rook
                })
            );

            //set black pawn
            let mut i: u32 = 0;
            while i <= 7 {
                set!(
                     world,
                     (Piece {
                         game_id,
                         color: Color::Black,
                         position: Vec2 { x: i, y: 6 },
                         piece_type: PieceType::Pawn
                    })
                );
                i += 1;
            };
 
            // set black Knight
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::Black,
                    position: Vec2 { x: 1, y: 7 },
                    piece_type: PieceType::Knight
                })
            );
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::Black,
                    position: Vec2 { x: 6, y: 7 },
                    piece_type: PieceType::Knight
                })
            );

            //set black Bishop
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::Black,
                    position: Vec2 { x: 2, y: 7 },
                    piece_type: PieceType::Bishop,
                })
            );
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::Black,
                    position: Vec2 { x: 5, y: 7 },
                    piece_type: PieceType::Bishop,
                })
            );

            //set black Queen
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::Black,
                    position: Vec2 { x: 3, y: 7 },
                    piece_type: PieceType::Queen
                })
            );

            // set black King
            set!(
                world,
                (Piece {
                    game_id,
                    color: Color::Black,
                    position: Vec2 { x: 4, y: 7 },
                    piece_type: PieceType::King
                })
            );

            //return game id
            game_id
        }
    }
}