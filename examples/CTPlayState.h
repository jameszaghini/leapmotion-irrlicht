//
//  CTPlayState.h
//  Contratempo
//
//  Created by James Zaghini on 30/12/12.
//
//

#ifndef __Contratempo__CTPlayState__
#define __Contratempo__CTPlayState__

#include "irrlicht.h"
#include "CTEventReceiver.h"
#include "CTGameState.h"
#include "CTPauseState.h"
#include "CTAudioController.h"
#include "Leap.h"
#include "CTBulletHelper.h"

using namespace irr;
using namespace core;
using namespace video;
using namespace scene;
using namespace Leap;


class CPlayState : public CGameState
{
public:
	void Init(CGameEngine* game);
	void Cleanup();
	
	void Pause();
	void Resume();
	
	void HandleEvents(CGameEngine* game);
	void Update(CGameEngine* game);
	void Draw(CGameEngine* game);
	
	static CPlayState* Instance() {
		return &m_PlayState;
	}

protected:
	CPlayState() { }
	
private:
	static CPlayState m_PlayState;
	
	IVideoDriver *driver;
	ISceneManager *smgr;
		
	ITexture *crosshairImage;
    
    IAnimatedMeshSceneNode *handsNode;
    SMaterial handsMaterial;

	// Create a sample listener and controller
	Listener listener;
	Controller controller;
    
	ITimer* timer;
	u32 then, now;
	
	CTBulletHelper *bulletHelper;
};

#endif /* defined(__Contratempo__CTPlayState__) */
