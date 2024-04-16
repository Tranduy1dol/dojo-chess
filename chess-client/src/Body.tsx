import React, {useEffect, useState} from "react";
import Button from "./Components/Button/Button";
import {setupNetwork, SpawnGame} from "./dojo/setupNetwork";
import Chessboard from "./Components/Chessboard/Chessboard";

export enum State {
    Init,
    Spawn,
    Playing,
    End,
}

export function Body() {
    const [state, setState] = useState<State>(State.Init);
    const [gameId, setGameId] = useState(1);
    const [playerAddresses, setPlayerAddresses] = useState({white: "", black: ""});

    useEffect(() => {
        const network = setupNetwork();
        if (state === State.Spawn) SpawnGame(network).then(addresses => {
            setPlayerAddresses(addresses);
            setState(State.Playing);
        })
    }, [state]);

    const handleReset = () => {
        setState(State.Init);
        setGameId((prevState) => prevState + 1);
    }

    return (
        <div>
            {state === State.Init && (
                <Button onClick={() => setState(State.Spawn)}>Start Game</Button>
            )}
            {state === State.Spawn &&
                <div className="text-color">
                    Loading board...
                </div>}
            {state === State.Playing && <div>
                <Button onClick={() => handleReset()}>
                    <div className="top-left-button"> Reset</div>
                </Button>
                <Chessboard gameId={gameId} playerAddresses={playerAddresses}/>
            </div>}
            {state === State.End && <p>
                Checkmate! Game Over.
                <Button onClick={() => handleReset()}>Play one more time!</Button>
            </p>}
        </div>
    );
}