//
//  CTPlayState.cpp
//  Contratempo
//
//  Created by James Zaghini on 30/12/12.
//
//

#include <stdio.h>
#include <Foundation/Foundation.h>
#include "CTPlayState.h"
#include "CTGameState.h"
#include "CTGameEngine.h"
#include "CTPlayState.h"

static btDiscreteDynamicsWorld *World;
static core::list<btRigidBody *> Objects;
static int GetRandInt(int TMax) { return rand() % TMax; }

CPlayState CPlayState::m_PlayState;

// Create a box rigid body
void CPlayState::CreateBox(const btVector3 &TPosition, const core::vector3df &TScale, btScalar TMass) {
	
	// Create an Irrlicht cube
	scene::ISceneNode *Node = smgr->addCubeSceneNode(1.0f);
	Node->setScale(TScale);
	Node->setMaterialFlag(video::EMF_LIGHTING, 1);
	Node->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	Node->setMaterialTexture(0, driver->getTexture("concrete-1.jpg"));
	
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
void CPlayState::CreateSphere(const btVector3 &TPosition, btScalar TRadius, btScalar TMass) {
	
	// Create an Irrlicht sphere
	scene::ISceneNode *Node = smgr->addSphereSceneNode(TRadius, 32);
	Node->setMaterialFlag(video::EMF_LIGHTING, 1);
	Node->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	Node->setMaterialTexture(0, driver->getTexture("concrete-1.jpg"));
	
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


void CPlayState::Init(CGameEngine* game)
{
	printf("CPlayState Init\n");
    
	timer = game->device->getTimer();
	then = timer->getTime();
	
    [[NSFileManager defaultManager]
     changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	
	// Initialize bullet
	btBroadphaseInterface *BroadPhase = new btAxisSweep3(btVector3(-1000, -1000, -1000), btVector3(1000, 1000, 1000));
	btDefaultCollisionConfiguration *CollisionConfiguration = new btDefaultCollisionConfiguration();
	btCollisionDispatcher *Dispatcher = new btCollisionDispatcher(CollisionConfiguration);
	btSequentialImpulseConstraintSolver *Solver = new btSequentialImpulseConstraintSolver();
	World = new btDiscreteDynamicsWorld(Dispatcher, BroadPhase, Solver, CollisionConfiguration);
	
	driver = game->device->getVideoDriver();
	smgr = game->device->getSceneManager();
	
	smgr->loadScene("cube.irr");
	
	SKeyMap *keyMap = new SKeyMap();
	keyMap[0].Action = EKA_MOVE_FORWARD;
	keyMap[0].KeyCode = KEY_KEY_W;
	
	keyMap[1].Action = EKA_MOVE_BACKWARD;
	keyMap[1].KeyCode = KEY_KEY_S;
	
	keyMap[2].Action = EKA_STRAFE_LEFT;
	keyMap[2].KeyCode = KEY_KEY_A;
	
	keyMap[3].Action = EKA_STRAFE_RIGHT;
	keyMap[3].KeyCode = KEY_KEY_D;
	
	keyMap[4].Action = EKA_CROUCH;
	keyMap[4].KeyCode = KEY_KEY_E;
	
	keyMap[5].Action = EKA_JUMP_UP;
	keyMap[5].KeyCode = KEY_SPACE;
	
	float rotationSpeed = 100.0f;
	float moveSpeed = 0.15f;
	float jumpSpeed = 7.f;
	
	
	ICameraSceneNode * camera = smgr->addCameraSceneNodeFPS(0, rotationSpeed,  moveSpeed, 0, keyMap, 6, true, jumpSpeed);
	
	// Create a meta triangle selector to hold several triangle selectors.
	scene::IMetaTriangleSelector * meta = smgr->createMetaTriangleSelector();
	
	/*
	 Now we will find all the nodes in the scene and create triangle
	 selectors for all suitable nodes.  Typically, you would want to make a
	 more informed decision about which nodes to performs collision checks
	 on; you could capture that information in the node name or Id.
	 */
	core::array<scene::ISceneNode *> nodes;
	smgr->getSceneNodesFromType(scene::ESNT_ANY, nodes); // Find all nodes
	
	for (u32 i=0; i < nodes.size(); ++i)
	{
		scene::ISceneNode * node = nodes[i];
		scene::ITriangleSelector * selector = 0;
		
		switch(node->getType())
		{
			case scene::ESNT_CUBE:
			case scene::ESNT_ANIMATED_MESH:
				// Because the selector won't animate with the mesh,
				// and is only being used for camera collision, we'll just use an approximate
				// bounding box instead of ((scene::IAnimatedMeshSceneNode*)node)->getMesh(0)
				selector = smgr->createTriangleSelectorFromBoundingBox(node);
				break;
				
			case scene::ESNT_MESH:
			case scene::ESNT_SPHERE: // Derived from IMeshSceneNode
				selector = smgr->createTriangleSelector(((scene::IMeshSceneNode*)node)->getMesh(), node);
				break;
				
			case scene::ESNT_TERRAIN:
				selector = smgr->createTerrainTriangleSelector((scene::ITerrainSceneNode*)node);
				break;
				
			case scene::ESNT_OCTREE:
				selector = smgr->createOctreeTriangleSelector(((scene::IMeshSceneNode*)node)->getMesh(), node);
				break;
				
			default:
				// Don't create a selector for this node type
				break;
		}
		
		if(selector)
		{
			// Add it to the meta selector, which will take a reference to it
			meta->addTriangleSelector(selector);
			// And drop my reference to it, so that the meta selector owns it.
			selector->drop();
		}
	}
	
	/*
	 Now that the mesh scene nodes have had triangle selectors created and added
	 to the meta selector, create a collision response animator from that meta selector.
	 */
	
	scene::ISceneNodeAnimator* anim = smgr->createCollisionResponseAnimator(
																			meta, camera, core::vector3df(3,3,3),
																			core::vector3df(0,-35,0), core::vector3df(0,30,0));
	meta->drop(); // I'm done with the meta selector now
	
	camera->addAnimator(anim);
	anim->drop(); // I'm done with the animator now
	
	// And set the camera position so that it doesn't start off stuck in the geometry
	camera->setPosition(core::vector3df(95.0f, 1.00f, -6.0f));
	
	scene::IAnimatedMeshSceneNode* node = 0;
	scene::IMeshSceneNode *node2 = 0;

	
    [[NSFileManager defaultManager]
     changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    
	gunNode = smgr->addAnimatedMeshSceneNode(smgr->getMesh("Hand1.b3d"), 0, 0 | 0);
	gunNode->setPosition(core::vector3df(6,-11,8)); // Put its feet on the floor.
	gunNode->setRotation(core::vector3df(150,0,340));
	gunNode->setScale(core::vector3df(5, 5, 5)); // Make it appear realistically scaled
	gunNode->setMD2Animation(scene::EMAT_POINT);
	gunNode->setAnimationSpeed(20.f);
	
//	gunMaterial.setTexture(0, driver->getTexture("default_skyboxbup.jpg"));
	gunMaterial.Lighting = true;
	gunMaterial.NormalizeNormals = true;
	
	gunNode->getMaterial(0) = gunMaterial;
	
	camera->addChild(gunNode);
	
	
    [[NSFileManager defaultManager]
     changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];

	
	CreateBox(btVector3(0.0f, -50.0f, 0.0f), core::vector3df(20.0f, 1.0f, 20.0f), 0.0f);
	CreateBox(btVector3(0.0f, -72.0f, 0.0f), core::vector3df(100.0f, 1.0f, 100.0f), 0.0f);
}

void CPlayState::Cleanup()
{
	printf("CPlayState Cleanup\n");
}

void CPlayState::Pause()
{
	printf("CPlayState Pause\n");
}

void CPlayState::Resume()
{
	printf("CPlayState Resume\n");
}

// Runs the physics simulation.
// - TDeltaTime tells the simulation how much time has passed since the last frame so the simulation can run independently of the frame rate.
void CPlayState::UpdatePhysics(u32 TDeltaTime) {
	
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
void CPlayState::QuaternionToEuler(const btQuaternion &TQuat, btVector3 &TEuler) {
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

void CPlayState::HandleEvents(CGameEngine* game)
{
    if(game->receiver.IsKeyPressed(KEY_KEY_P)) {
        game->PushState(CPauseState::Instance());
	}
	
	core::vector3df rotation = gunNode->getRotation();

	printf("%f, %f, %f\n", rotation.X, rotation.Y, rotation.Z);
	
	if(game->receiver.IsKeyPressed(KEY_KEY_X)) {
		gunNode->setRotation(core::vector3df(rotation.X + 10, rotation.Y, rotation.Z));
	}
	if(game->receiver.IsKeyPressed(KEY_KEY_Y)) {
		gunNode->setRotation(core::vector3df(rotation.X, rotation.Y+10, rotation.Z));
	}
	if(game->receiver.IsKeyPressed(KEY_KEY_Z)) {
		gunNode->setRotation(core::vector3df(rotation.X, rotation.Y, rotation.Z+10));
	}
	
    if(game->receiver.IsKeyDown(KEY_ESCAPE)) {
        exit(0);
    }
    
    if(game->receiver.IsKeyDown(KEY_KEY_O)) {
		CreateBox(btVector3(GetRandInt(10) - 5.0f, 50.0f, GetRandInt(10) - 5.0f), core::vector3df(GetRandInt(3) + 0.5f, GetRandInt(3) + 0.5f, GetRandInt(3) + 0.5f), 1.0f);     
    }
	
    if(game->receiver.IsKeyDown(KEY_KEY_I)) {
		CreateSphere(btVector3(GetRandInt(10) - 5.0f, 7.0f, GetRandInt(10) - 5.0f), GetRandInt(5) / 5.0f + 0.2f, 1.0f);
    }
	
    if(game->receiver.GetMouseState().RightButtonPressed) {
		printf("rmb pressed\n");
		CreateBox(btVector3(GetRandInt(10) - 5.0f, 50.0f, GetRandInt(10) - 5.0f), core::vector3df(GetRandInt(3) + 0.5f, GetRandInt(3) + 0.5f, GetRandInt(3) + 0.5f), 1.0f);

    }

    if(game->receiver.GetMouseState().LeftButtonPressed) {
		then = timer->getTime();
	}
	
	game->receiver.reset();
}

void CPlayState::Update(CGameEngine* game)
{
	now = timer->getTime();
	
	if(now > then + 100) {
	}
}

void CPlayState::Draw(CGameEngine* game)
{
	int lastFPS = -1;
	
	bool soundplaying = false;
	
	if(game->device->run()) {
		if (game->device->isWindowActive())
		{
            UpdatePhysics(50);
			
			
			driver->beginScene(true, true, video::SColor(0,200,200,200));
						
			smgr->drawAll();

			driver->draw2DImage(crosshairImage, core::position2d<s32>(game->getWidth()/2-24/2, game->getHeight()/2-24/2), core::rect<s32>(0, 0, 24, 24), 0, video::SColor(255,255,255,255), true);
			
			driver->endScene();
			
			int fps = driver->getFPS();
			if (lastFPS != fps)
			{
				core::stringw str = L"Contratempo [";
				str += driver->getName();
				str += "] FPS:";
				str += fps;
				
				game->device->setWindowCaption(str.c_str());
				lastFPS = fps;
			}
			
			//		irr::core::vector3df pos = camera->getAbsolutePosition();
			//		printf("%f, %f, %f\n", pos.X, pos.Y, pos.Z);
		}
	}
}