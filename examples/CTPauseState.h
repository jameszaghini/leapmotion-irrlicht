//
//  CTPauseState.h
//  Contratempo
//
//  Created by James Zaghini on 2/01/13.
//
//

#ifndef __Contratempo__CTPauseState__
#define __Contratempo__CTPauseState__

#include <iostream>
#include "irrlicht.h"
#include "CTEventReceiver.h"
#include "CTGameState.h"

using namespace irr;
using namespace core;
using namespace video;
using namespace scene;
using namespace gui;

class CPauseState : public CGameState
{
public:
	void Init(CGameEngine* game);
	void Cleanup();
	
	void Pause();
	void Resume();
	
	void HandleEvents(CGameEngine* game);
	void Update(CGameEngine* game);
	void Draw(CGameEngine* game);
	
	static CPauseState* Instance() {
		return &m_PauseState;
	}
	
protected:
	CPauseState() { }
	
private:
	static CPauseState m_PauseState;
	
	IVideoDriver *driver;
	ISceneManager *smgr;
    
    ITexture *pauseImage;
    IGUIFont *font;
};

#endif /* defined(__Contratempo__CTPauseState__) */
