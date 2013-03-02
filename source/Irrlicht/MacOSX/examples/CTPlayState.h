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
#include "CTAudioController.h"
#include "Leap.h"
#include "CTBulletHelper.h"

using namespace irr;
using namespace core;
using namespace video;
using namespace scene;
using namespace gui;
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
    
	CGameEngine* game;
	
	IGUIEnvironment *env;
	IGUIEditBox *posX, *posY, *posZ;
	IGUIEditBox *rotX, *rotY, *rotZ;
	IGUIListBox *boneListBox;
	
	static CPlayState m_PlayState;

	IVideoDriver *driver;
	ISceneManager *smgr;
    
    ICameraSceneNode *camera;
    
    IAnimatedMeshSceneNode *handsNode;
    SMaterial handsMaterial;
	SMaterial planeMaterial;

	// Create a sample listener and controller
	Listener listener;
	Controller controller;
    
	ITimer *timer;
	u32 then, now;
	
	CTBulletHelper *bulletHelper;
	
	IBoneSceneNode *leftHandBone;
	IBoneSceneNode *indexFingerBone;
	IBoneSceneNode *pinkyFingerBone;
	IBoneSceneNode *ringFingerBone;
	IBoneSceneNode *middleFingerBone;
	IBoneSceneNode *thumbBone;
	
	void initCamera();
    void initGUI();
	void initSky();
	void initLights();
	void initPlane();
	void initHands();
	void initBones();
	
	void getAllBones();
	
	void leapLog(const Frame frame);
	
	void updateHand();

	
};

#endif /* defined(__Contratempo__CTPlayState__) */
