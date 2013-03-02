//
//  CTGameState.h
//  Contratempo
//
//  Created by James Zaghini on 30/12/12.
//
//  http://gamedevgeek.com/tutorials/managing-game-states-in-c/

#ifndef __Contratempo__CTGameState__
#define __Contratempo__CTGameState__

#include "CTGameEngine.h"
#include "CTEventReceiver.h"

class CGameState
{
public:
	virtual void Init(CGameEngine* game) = 0;
	virtual void Cleanup() = 0;
	
	virtual void Pause() = 0;
	virtual void Resume() = 0;
	
	virtual void HandleEvents(CGameEngine* game) = 0;
	virtual void Update(CGameEngine* game) = 0;
	virtual void Draw(CGameEngine* game) = 0;
	
	void ChangeState(CGameEngine* game, CGameState* state) {
		game->ChangeState(state);
	}
	
protected:
	CGameState() { }
};


#endif /* defined(__Contratempo__CTGameState__) */
