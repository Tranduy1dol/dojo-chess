import {Account, CallData, Contract, RpcProvider} from "starknet";
import {Vec2} from "../Components/Chessboard/Chessboard";
import {abi} from "./abi";

export const KATANA_ACCOUNT_ADDRESS = "0x6162896d1d7ab204c7ccac6dd5f8e9e7c25ecd5ae4fcb4ad32e57786bb46e03";
export const KATANA_ACCOUNT_PRIVATE_KEY = "0x1800000000300000180000000000030000000000003006001800006600";
export const PLAYER_CLASS_HASH = "0x1d6bd75d205c34901674c6e42c282b3bfb8d179a4a60de2b2a4d6329ad1766e";
export const WORLD_CONTRACT_ADDRESS = "0x23907fff4d969aa0f22a0e53842148e65aeebe30448b050b4b71698cf179c97";
export const KATANA_RPC = "http://localhost:5050/";

export function setupNetwork() {
    const provider = new RpcProvider({nodeUrl: KATANA_RPC});

    const signer = new Account(
        provider,
        KATANA_ACCOUNT_ADDRESS,
        KATANA_ACCOUNT_PRIVATE_KEY
    );
    return {
        provider,
        signer,
    }
}

export async function SpawnGame({provider, signer}:{ provider: RpcProvider; signer: Account }) {

    const white = generateRandomHexString();
    const black = generateRandomHexString();

    //create a system contract and connect to account
    const contractCallData = new CallData(abi);
    const system_contract = new Contract(abi, WORLD_CONTRACT_ADDRESS, provider);
    system_contract.connect(signer);

    //create a white player contract
    // const white_contract = await signer.deployContract({classHash: PLAYER_CLASS_HASH});
    // const white = white_contract.contract_address;
    //
    //create a black player contract
    // const black_contract = await signer.deployContract({classHash: PLAYER_CLASS_HASH});
    // const black = black_contract.contract_address;
    //
    //call contract method to generate new game
    await system_contract.invoke(
        'spawn',
        contractCallData.compile('spawn', {
            white_address: white,
            black_address: black,
        }),
        {
            maxFee: 0,
        })

    console.log(white, "\n", black);

    //export player contract
    return {white, black}
}

export async function callMove(curr_position: Vec2, next_position: Vec2, game_id: number, caller: String, {provider, signer}:{ provider: RpcProvider; signer: Account }) {
    //create call data compiler and connect contract to account
    const contractCallData = new CallData(abi);
    const system_contract = new Contract(abi, WORLD_CONTRACT_ADDRESS, setupNetwork().provider);
    system_contract.connect(signer);

    await system_contract.invoke(
        'is_legal_move',
        contractCallData.compile("is_legal_move", {
            game_id: game_id,
            curr_position: curr_position,
            next_position: next_position,
            caller: caller
        }), {
            maxFee: 0,
        }
    )
    let result = await system_contract.get_move_result(game_id, curr_position, next_position);
    console.log(result);
    return result;
}

function generateRandomHexString(length = 32) {
    const allowedChars = '0123456789abcdef';

    // Loop until a valid random value is generated
    let randomString;
    do {
        randomString = '';
        for (let i = 0; i < length; i++) {
            randomString += allowedChars[Math.floor(Math.random() * allowedChars.length)];
        }
    } while (parseInt(randomString, 16) === 0); // Check if the value is zero

    // Prefix the string with "0x"
    return `0x${randomString}`;
}
