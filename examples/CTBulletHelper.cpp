//
//  CTBulletHelper.cpp
//  MacOSX
//
//  Created by James Zaghini on 9/02/13.
//
//

#include "CTBulletHelper.h"

CTBulletHelper::CTBulletHelper() { }

CTBulletHelper::CTBulletHelper(IVideoDriver *driver, ISceneManager *smgr)
{
	this->driver = driver;
	this->smgr = smgr;
	
	// Initialize bullet
	btBroadphaseInterface *BroadPhase = new btAxisSweep3(btVector3(-1000, -1000, -1000), btVector3(1000, 1000, 1000));
	btDefaultCollisionConfiguration *CollisionConfiguration = new btDefaultCollisionConfiguration();
	btCollisionDispatcher *Dispatcher = new btCollisionDispatcher(CollisionConfiguration);
	btSequentialImpulseConstraintSolver *Solver = new btSequentialImpulseConstraintSolver();
	World = new btDiscreteDynamicsWorld(Dispatcher, BroadPhase, Solver, CollisionConfiguration);
}


// Runs the physics simulation.
// - TDeltaTime tells the simulation how much time has passed since the last frame so the simulation can run independently of the frame rate.
void CTBulletHelper::UpdatePhysics(u32 TDeltaTime) {
	
	World->stepSimulation(TDeltaTime * 0.001f, 60);
	
	btRigidBody *TObject;
	// Relay the object's orientation to irrlicht
	for(core::list<btRigidBody *>::Iterator it = Objects.begin(); it != Objects.end(); ++it) {
		
		//UpdateRender(*Iterator);
		scene::ISceneNode *Node = static_cast<scene::ISceneNode *>((*it)->getUserPointer());
		TObject = *it;
		
		// Set position
		btVector3 Point = TObject->getCenterOfMassPosition();
		Node->setPosition(core::vector3df((f32)Point[0], (f32)Point[1], (f32)Point[2]));
		
		// Set rotation
		btVector3 EulerRotation;
		QuaternionToEuler(TObject->getOrientation(), EulerRotation);
		Node->setRotation(core::vector3df(EulerRotation[0], EulerRotation[1], EulerRotation[2]));
		
	}
}

// Converts a quaternion to an euler angle
void CTBulletHelper::QuaternionToEuler(const btQuaternion &TQuat, btVector3 &TEuler) {
	btScalar W = TQuat.getW();
	btScalar X = TQuat.getX();
	btScalar Y = TQuat.getY();
	btScalar Z = TQuat.getZ();
	float WSquared = W * W;
	float XSquared = X * X;
	float YSquared = Y * Y;
	float ZSquared = Z * Z;
	
	TEuler.setX(atan2f(2.0f * (Y * Z + X * W), -XSquared - YSquared + ZSquared + WSquared));
	TEuler.setY(asinf(-2.0f * (X * Z - Y * W)));
	TEuler.setZ(atan2f(2.0f * (X * Y + Z * W), XSquared - YSquared - ZSquared + WSquared));
	TEuler *= core::RADTODEG;
}

// Create a box rigid body
void CTBulletHelper::CreateBox(const btVector3 &TPosition, const core::vector3df &TScale, btScalar TMass, std::string textureFile) {
	
	// Create an Irrlicht cube
	scene::ISceneNode *Node = smgr->addCubeSceneNode(1.0f);
	Node->setScale(TScale);
	Node->setMaterialFlag(video::EMF_LIGHTING, 1);
	Node->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	
	io::path texturePath = textureFile.c_str();
	
	Node->setMaterialTexture(0, driver->getTexture(texturePath));
	
	// Set the initial position of the object
	btTransform Transform;
	Transform.setIdentity();
	Transform.setOrigin(TPosition);
	
	// Give it a default MotionState
	btDefaultMotionState *MotionState = new btDefaultMotionState(Transform);
	
	// Create the shape
	btVector3 HalfExtents(TScale.X * 0.5f, TScale.Y * 0.5f, TScale.Z * 0.5f);
	btCollisionShape *Shape = new btBoxShape(HalfExtents);
	
	// Add mass
	btVector3 LocalInertia;
	Shape->calculateLocalInertia(TMass, LocalInertia);
	
	// Create the rigid body object
	btRigidBody *RigidBody = new btRigidBody(TMass, MotionState, Shape, LocalInertia);
	
	// Store a pointer to the irrlicht node so we can update it later
	RigidBody->setUserPointer((void *)(Node));
	
	// Add it to the world
	World->addRigidBody(RigidBody);
	Objects.push_back(RigidBody);
}

// Create a sphere rigid body
void CTBulletHelper::CreateSphere(const btVector3 &TPosition, btScalar TRadius, btScalar TMass) {
	
	// Create an Irrlicht sphere
	scene::ISceneNode *Node = smgr->addSphereSceneNode(TRadius, 32);
	Node->setMaterialFlag(video::EMF_LIGHTING, 1);
	Node->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	Node->setMaterialTexture(0, driver->getTexture("water.jpg"));
	
	// Set the initial position of the object
	btTransform Transform;
	Transform.setIdentity();
	Transform.setOrigin(TPosition);
	
	// Give it a default MotionState
	btDefaultMotionState *MotionState = new btDefaultMotionState(Transform);
	
	// Create the shape
	btCollisionShape *Shape = new btSphereShape(TRadius);
	
	// Add mass
	btVector3 LocalInertia;
	Shape->calculateLocalInertia(TMass, LocalInertia);
	
	// Create the rigid body object
	btRigidBody *RigidBody = new btRigidBody(TMass, MotionState, Shape, LocalInertia);
	
	// Store a pointer to the irrlicht node so we can update it later
	RigidBody->setUserPointer((void *)(Node));
	
	// Add it to the world
	World->addRigidBody(RigidBody);
	Objects.push_back(RigidBody);
}
