//
//  CTBulletHelper.h
//  MacOSX
//
//  Created by James Zaghini on 9/02/13.
//
//

#ifndef __MacOSX__CTBulletHelper__
#define __MacOSX__CTBulletHelper__

#include <iostream>
#include "irrlicht.h"
#include  <BulletDynamics/btBulletDynamicsCommon.h>

using namespace irr;
using namespace video;
using namespace scene;
using namespace core;

class CTBulletHelper
{
public:
	CTBulletHelper();
	CTBulletHelper(IVideoDriver *driver, ISceneManager *smgr);
	void UpdatePhysics(u32 TDeltaTime);

	
private:
	void CreateBox(const btVector3 &TPosition, const core::vector3df &TScale, btScalar TMass, std::string textureFile);
	void CreateSphere(const btVector3 &TPosition, btScalar TRadius, btScalar TMass);
	void QuaternionToEuler(const btQuaternion &TQuat, btVector3 &TEuler);
	
	btDiscreteDynamicsWorld *World;
	core::list<btRigidBody *> Objects;
	int GetRandInt(int TMax) { return rand() % TMax; }
	
	IVideoDriver *driver;
	ISceneManager *smgr;
};

#endif /* defined(__MacOSX__CTBulletHelper__) */
