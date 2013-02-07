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
#include  <BulletDynamics/btBulletDynamicsCommon.h>
#include "Leap.h"

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
	
	void CreateBox(const btVector3 &TPosition, const core::vector3df &TScale, btScalar TMass);
	void CreateSphere(const btVector3 &TPosition, btScalar TRadius, btScalar TMass);
	void UpdatePhysics(u32 TDeltaTime);
	void QuaternionToEuler(const btQuaternion &TQuat, btVector3 &TEuler);
	
protected:
	CPlayState() { }
	
private:
	static CPlayState m_PlayState;
	
	IVideoDriver *driver;
	ISceneManager *smgr;
		
	ITexture *crosshairImage;
    
    IAnimatedMeshSceneNode* gunNode;
    SMaterial gunMaterial;
    ISceneNode *gunFlareBillboardNode;
    bool gunSoundPlaying = false;

	// Create a sample listener and controller
	Listener listener;
	Controller controller;
    
	ITimer* timer;
	u32 then, now;
    
};

#endif /* defined(__Contratempo__CTPlayState__) */
