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
#include <sstream>

CPlayState CPlayState::m_PlayState;

static wchar_t temp;

const wchar_t* getstring_float(float num)
{
	swprintf(&temp, 32, L"%3.2f", num);
	return &temp;
}

void CPlayState::initalizeGUI(CGameEngine* game)
{
	env = game->device->getGUIEnvironment();
	
	core::vector3df rotation = handsNode->getRotation();
    core::vector3df position = handsNode->getPosition();
	
	env->addStaticText(L"Rotation x,y,z", rect<s32>(10,1,100,10));
	
	rotX = env->addEditBox(getstring_float(rotation.X), rect<s32>(10,10,100,25));
	rotY = env->addEditBox(getstring_float(rotation.Y), rect<s32>(10,35,100,50));
	rotZ = env->addEditBox(getstring_float(rotation.Z), rect<s32>(10,60,100,75));
	
	env->addStaticText(L"Position x,y,z", rect<s32>(10,84,100,94));
	
	posX = env->addEditBox(getstring_float(position.X), rect<s32>(10,95,100,110));
	posY = env->addEditBox(getstring_float(position.Y), rect<s32>(10,120,100,135));
	posZ = env->addEditBox(getstring_float(position.Z), rect<s32>(10,145,100,160));
}

void CPlayState::leapLog(const Frame frame)
{
	//            std::cout << "Frame id: " << frame.id()
	//            << ", timestamp: " << frame.timestamp()
	//            << ", hands: " << frame.hands().count()
	//            << ", fingers: " << frame.fingers().count()
	//            << ", tools: " << frame.tools().count() << std::endl;
	
	if (!frame.hands().empty()) {
		// Get the first hand
		const Hand hand = frame.hands()[0];
		
		// Check if the hand has any fingers
		const FingerList fingers = hand.fingers();
		if (!fingers.empty()) {
			// Calculate the hand's average finger tip position
			Vector avgPos;
			for (int i = 0; i < fingers.count(); ++i) {
				
				avgPos += fingers[i].tipPosition();
			}
			avgPos /= (float)fingers.count();
			//                    std::cout << "Hand has " << fingers.count()
			//                    << " fingers, average finger tip position" << avgPos << std::endl;
		}
		
		// Get the hand's sphere radius and palm position
		//                std::cout << "Hand sphere radius: " << hand.sphereRadius()
		//                << " mm, palm position: " << hand.palmPosition() << std::endl;
		
		// Get the hand's normal vector and direction
		const Vector normal = hand.palmNormal();
		const Vector direction = hand.direction();
		
		// Calculate the hand's pitch, roll, and yaw angles
		//                std::cout << "Hand pitch: " << direction.pitch() * RAD_TO_DEG << " degrees, "
		//                << "roll: " << normal.roll() * RAD_TO_DEG << " degrees, "
		//                << "yaw: " << direction.yaw() * RAD_TO_DEG << " degrees" << std::endl << std::endl;
		
		// Get the hand's normal vector and direction
		//                const LeapVector *normal = [hand palmNormal];
		//                const LeapVector *direction = [hand direction];
		//
		//                // Calculate the hand's pitch, roll, and yaw angles
		//                NSLog(@"Hand pitch: %f degrees, roll: %f degrees, yaw: %f degrees\n",
		//                      [direction pitch] * LEAP_RAD_TO_DEG,
		//                      [normal roll] * LEAP_RAD_TO_DEG,
		//                      [direction yaw] * LEAP_RAD_TO_DEG);
	}
}

void CPlayState::Init(CGameEngine* game)
{
	printf("CPlayState Init\n");
  
	// Have the sample listener receive events from the controller
	controller.addListener(listener);
    
	timer = game->device->getTimer();
	then = timer->getTime();
	
    [[NSFileManager defaultManager]
     changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	
	driver = game->device->getVideoDriver();
	smgr = game->device->getSceneManager();

	bulletHelper = new CTBulletHelper(driver, smgr);
	
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
	
	handsNode = smgr->addAnimatedMeshSceneNode(smgr->getMesh("Hand_v.4.b3d"), 0, 0 | 0);
	handsNode->setPosition(core::vector3df(83,-60,5));
	handsNode->setRotation(core::vector3df(38,160,30));
	handsNode->setScale(core::vector3df(12, 12, 12));
	handsNode->setMaterialFlag(video::EMF_LIGHTING, 1);
	handsNode->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	handsNode->setJointMode(irr::scene::EJUOR_CONTROL);
	handsMaterial.setTexture(0, driver->getTexture("HAND_C.jpg"));
	handsMaterial.Lighting = true;
	handsMaterial.NormalizeNormals = true;
//
	handsNode->getMaterial(0) = handsMaterial;
   
	this->initalizeGUI(game);

	//camera->addChild(handsNode);
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

void CPlayState::HandleEvents(CGameEngine* game)
{
    if(game->receiver.IsKeyPressed(KEY_KEY_P)) {
        game->PushState(CPauseState::Instance());
	}
	
	if(game->receiver.IsKeyPressed(KEY_RETURN)) {
		
		float x = (float)wcstod(posX->getText(), NULL);
		float y = (float)wcstod(posY->getText(), NULL);
		float z = (float)wcstod(posZ->getText(), NULL);
		
		handsNode->setPosition(vector3df(x,y,z));
		
		x = (float)wcstod(rotX->getText(), NULL);
		y = (float)wcstod(rotY->getText(), NULL);
		z = (float)wcstod(rotZ->getText(), NULL);
		
		handsNode->setRotation(vector3df(x,y,z));
	}
	
	
    if(game->receiver.IsKeyDown(KEY_ESCAPE)) {
        exit(0);
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

            bulletHelper->UpdatePhysics(50);
		
            // Get the most recent frame and report some basic information
            const Frame frame = controller.frame();
			this->leapLog(frame);

			if (!frame.hands().empty()) {
				
				// Get the first hand
				const Hand hand = frame.hands()[0];
				
				const Vector normal = hand.palmNormal();
				const Vector direction = hand.direction();
				
				float x = ((direction.pitch() * RAD_TO_DEG - 30) * -1);
                float y = (direction.yaw() * RAD_TO_DEG) - 50;
                float z = (normal.roll() * RAD_TO_DEG) + 50;
				
				IBoneSceneNode* Head = handsNode->getJointNode("hand.L");
				
				Head->setRotation(vector3df(x,y,z));
				
//				handsNode->setRotation(core::vector3df(x, y, z));
				
				printf("%f, %f, %f\n\n", x,y,z);				
			}
            
			driver->beginScene(true, true, video::SColor(0,200,200,200));
						
			smgr->drawAll();
            env->drawAll();
			
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
		}
	}
}