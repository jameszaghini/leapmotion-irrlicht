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

CPlayState CPlayState::m_PlayState;

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
	
	scene::IAnimatedMeshSceneNode* node = 0;
	scene::IMeshSceneNode *node2 = 0;
    
	handsNode = smgr->addMeshSceneNode(smgr->getMesh("Hand_v.4.b3d"), 0, 0 | 0);
	handsNode->setPosition(core::vector3df(6,-11,30));
	handsNode->setRotation(core::vector3df(150,0,340));
	handsNode->setScale(core::vector3df(59, 59, 59));
	handsNode->setMaterialFlag(video::EMF_LIGHTING, 1);
	handsNode->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	
	handsMaterial.setTexture(0, driver->getTexture("HAND_C.jpg"));
	handsMaterial.Lighting = true;
	handsMaterial.NormalizeNormals = true;
	
	handsNode->getMaterial(0) = handsMaterial;
	
	camera->addChild(handsNode);
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
	
	core::vector3df rotation = handsNode->getRotation();

	printf("%f, %f, %f\n", rotation.X, rotation.Y, rotation.Z);
	
	if(game->receiver.IsKeyPressed(KEY_KEY_X)) {
		float x = rotation.X + 10;
		if(x>360) x -= 360;
		handsNode->setRotation(core::vector3df(x, rotation.Y, rotation.Z));
	}
	if(game->receiver.IsKeyPressed(KEY_KEY_Y)) {
		float y = rotation.Y + 10;
		if(y>360) y -= 360;
		handsNode->setRotation(core::vector3df(rotation.X, y, rotation.Z));
	}
	if(game->receiver.IsKeyPressed(KEY_KEY_Z)) {
		float z = rotation.Z + 10;
		if(z>360) z -= 360;
		handsNode->setRotation(core::vector3df(rotation.X, rotation.Y, z));
	}
	if(game->receiver.IsKeyPressed(KEY_KEY_J)) {
		float x = rotation.X - 10;
		if(x<0) x += 360;
		handsNode->setRotation(core::vector3df(x, rotation.Y, rotation.Z));
	}
	if(game->receiver.IsKeyPressed(KEY_KEY_K)) {
		float y = rotation.Y - 10;
		if(y<0) y += 360;
		handsNode->setRotation(core::vector3df(rotation.X, y, rotation.Z));
	}
	if(game->receiver.IsKeyPressed(KEY_KEY_L)) {
		float z = rotation.Z - 10;
		if(z<0) z += 360;
		handsNode->setRotation(core::vector3df(rotation.X, rotation.Y, z));
	}
    if(game->receiver.IsKeyDown(KEY_ESCAPE)) {
        exit(0);
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

            bulletHelper->UpdatePhysics(50);
			
		
            // Get the most recent frame and report some basic information
            const Frame frame = controller.frame();
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
                
//				float x = (direction.pitch() * RAD_TO_DEG * -1) + 160;
//                float y = (direction.yaw() * RAD_TO_DEG * 2) + 330;
//                float z = (normal.roll() * RAD_TO_DEG * -1) + 330;
               
				float x = (direction.pitch() * RAD_TO_DEG * -1);
                float y = (direction.yaw() * RAD_TO_DEG);
                float z = (normal.roll() * RAD_TO_DEG);
				
               // printf("%f, %f, %f\n\n", x,y,z);

                handsNode->setRotation(core::vector3df(x, y, z));
            }
            
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
		}
	}
}