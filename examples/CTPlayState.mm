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
#include <vector>

CPlayState CPlayState::m_PlayState;

static wchar_t temp;

const wchar_t* getstring_float(float num)
{
	swprintf(&temp, 32, L"%3.2f", num);
	return &temp;
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
	
	this->initPlane();
	this->initCamera();
	this->initSky();
	this->initLights();
	this->initHands();
	this->initBones();
	this->initGUI(game);
	this->getAllBones();
}

void CPlayState::initBones()
{
	leftHandBone = handsNode->getJointNode("hand.L");
	indexFingerBone = handsNode->getJointNode("finger_index.01.L");
	pinkyFingerBone = handsNode->getJointNode("finger_pinky.01.L");
	ringFingerBone = handsNode->getJointNode("finger_ring.01.L");
	middleFingerBone = handsNode->getJointNode("finger_middle.01.L");
	thumbBone = handsNode->getJointNode("thumb.01.L");
}

void CPlayState::getAllBones()
{
	int numberOfBones = handsNode->getJointCount();
	
	std::vector<IBoneSceneNode*> bones;
	
	for(int i=0; i < numberOfBones; i++) {
		
		IBoneSceneNode *bone = handsNode->getJointNode(i);

		const size_t cSize = strlen(bone->getName())+1;
		wchar_t* wc = new wchar_t[cSize];
		mbstowcs (wc, bone->getName(), cSize);
				
//		boneListBox->addItem(wc);
		
		delete wc;
		
		bones.push_back(bone);
	}
}

void CPlayState::initSky()
{
	[[NSFileManager defaultManager]
     changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	smgr->addSkyDomeSceneNode(driver->getTexture("skydome.jpg"),16,16,1.0f,2.0f);
}

void CPlayState::initLights()
{
	ILightSceneNode*  pLight = smgr->addLightSceneNode();
	SLight & l = pLight->getLightData();
	l.Type = ELT_DIRECTIONAL;
	l.CastShadows = true;
	
	smgr->setAmbientLight(SColorf(0.6f, 0.6f, 0.8f));
}

void CPlayState::initCamera()
{
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
	
	camera = smgr->addCameraSceneNodeFPS(0, rotationSpeed,  moveSpeed, 0, keyMap, 6, true, jumpSpeed);
	
    // Create a meta triangle selector to hold several triangle selectors.
	scene::IMetaTriangleSelector * meta = smgr->createMetaTriangleSelector();
	
	/*
	 Now we will find all the nodes in the scene and create triangle
	 selectors for all suitable nodes.  Typically, you would want to make a
	 more informed decision about which nodes to performs collision checks
	 on; you could capture that information in the node name or Id.
	 */
	array<scene::ISceneNode *> nodes;
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
	
	scene::ISceneNodeAnimator* anim;
	anim = smgr->createCollisionResponseAnimator(meta, camera, vector3df(3,3,3), vector3df(0,-10,0), vector3df(0,30,0));
	meta->drop(); // I'm done with the meta selector now
	
	camera->addAnimator(anim);
	anim->drop(); // I'm done with the animator now
	
	camera->setPosition(vector3df(0, 170, 0));
	camera->setRotation(vector3df(30, 120, 0));
}

void CPlayState::initGUI(CGameEngine* game)
{
	[[NSFileManager defaultManager]
     changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	
	env = game->device->getGUIEnvironment();
	IGUISkin *skin = env->getSkin();
	IGUIFont* font = env->getFont("fonthaettenschweiler.bmp");
    if (font)
        skin->setFont(font);
	
	vector3df rotation = camera->getRotation();
    vector3df position = camera->getPosition();

	int y = 10;
	
//	boneListBox = env->addListBox(rect<s32>(10, y, 100, y+15));
//	boneListBox->setDrawBackground(true);
	
	env->addStaticText(L"Rotation x,y,z", rect<s32>(10,y+=30,100,y+15));
	
	rotX = env->addEditBox(getstring_float(rotation.X), rect<s32>(10,y+=20,100,y+15));
	rotY = env->addEditBox(getstring_float(rotation.Y), rect<s32>(10,y+=20,100,y+15));
	rotZ = env->addEditBox(getstring_float(rotation.Z), rect<s32>(10,y+=20,100,y+15));
	
	env->addStaticText(L"Position x,y,z", rect<s32>(10,y+=30,100,y+15));
	
	posX = env->addEditBox(getstring_float(position.X), rect<s32>(10,y+=20,100,y+15));
	posY = env->addEditBox(getstring_float(position.Y), rect<s32>(10,y+=20,100,y+15));
	posZ = env->addEditBox(getstring_float(position.Z), rect<s32>(10,y+=20,100,y+15));
}

void CPlayState::leapLog(const Frame frame)
{
	//  std::cout << "Frame id: " << frame.id()
	//  << ", timestamp: " << frame.timestamp()
	//  << ", hands: " << frame.hands().count()
	//  << ", fingers: " << frame.fingers().count()
	//  << ", tools: " << frame.tools().count() << std::endl;
	
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
	}
}

void CPlayState::initPlane()
{
	planeMaterial.setTexture(0, driver->getTexture("concrete-1.jpg"));
	planeMaterial.Lighting = true;
	planeMaterial.NormalizeNormals = true;
	
	IMesh *plane = smgr->getGeometryCreator()->createPlaneMesh(dimension2df(1000,1000), dimension2du(1,1), &planeMaterial, dimension2df(1,1));
	
	ISceneNode *ground = smgr->addMeshSceneNode(plane);
}

void CPlayState::initHands()
{	
	handsNode = smgr->addAnimatedMeshSceneNode(smgr->getMesh("Hand_v.4.b3d"), 0, 0 | 0);
	handsNode->setPosition(vector3df(0,-150,0));
	handsNode->setRotation(vector3df(48,150,30));
	handsNode->setScale(vector3df(120, 120, 120));
	handsNode->setMaterialFlag(video::EMF_LIGHTING, 1);
	handsNode->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	handsNode->setJointMode(irr::scene::EJUOR_CONTROL);
	handsMaterial.setTexture(0, driver->getTexture("HAND_C.jpg"));
	handsMaterial.Lighting = true;
	handsMaterial.NormalizeNormals = true;
	
	handsNode->getMaterial(0) = handsMaterial;
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
	if(game->receiver.IsKeyPressed(KEY_RETURN)) {
		
		float x = (float)wcstod(posX->getText(), NULL);
		float y = (float)wcstod(posY->getText(), NULL);
		float z = (float)wcstod(posZ->getText(), NULL);
		
		camera->setPosition(vector3df(x,y,z));
		
		x = (float)wcstod(rotX->getText(), NULL);
		y = (float)wcstod(rotY->getText(), NULL);
		z = (float)wcstod(rotZ->getText(), NULL);
		
		camera->setRotation(vector3df(x,y,z));
	}
	
    if(game->receiver.IsKeyDown(KEY_ESCAPE)) {
		game->Quit();
    }
	
	game->receiver.reset();
}

void CPlayState::Update(CGameEngine* game)
{
	

}

void CPlayState::updateHand()
{
	// Get the most recent frame and report some basic information
	const Frame frame = controller.frame();
	//this->leapLog(frame);
	
	if (!frame.hands().empty()) {
		
		// Get the first hand
		const Hand hand = frame.hands()[0];
		
		const Vector normal = hand.palmNormal();
		const Vector direction = hand.direction();
		
		float x = ((direction.pitch() * RAD_TO_DEG) * -1) + 20;
		float y = ((normal.roll() * RAD_TO_DEG)) + 273;
		float z = ((direction.yaw() * RAD_TO_DEG)) + 19.82;
		
		const vector3df lhr = leftHandBone->getRotation();
		
		leftHandBone->setRotation(vector3df(x,y,lhr.Z));
		
		FingerList fingers = hand.fingers();
		
		// PINKY
		const vector3df pfr = pinkyFingerBone->getRotation();
		
		x = 15.3019; // inital bone x val
		if(fingers[0].isValid()) {
			const Vector pinkyDirection = fingers[3].direction();
			
			// for some reason, even when the finger is valid
			// I'd get 180 and it would make the pink bend back
			// very unnaturally
			if((pinkyDirection.pitch() * RAD_TO_DEG) != 180) { 
				x = (pinkyDirection.pitch() * RAD_TO_DEG * -1) + 15.3019;
			}
		}

		pinkyFingerBone->setRotation(vector3df(x,pfr.Y,pfr.Z));
		
		// RING
		const vector3df rfr = ringFingerBone->getRotation();
		//				std::cout << "Ring: " << rfr.X << std::endl;
		if(fingers[1].isValid()) {
			const Vector ringDirection = fingers[1].direction();
			x = (ringDirection.pitch() * RAD_TO_DEG * -1) + 8.035;
			ringFingerBone->setRotation(vector3df(x,rfr.Y,rfr.Z));
		}
		
		// MIDDLE
		const vector3df mfr = middleFingerBone->getRotation();
		//				std::cout << "Middle: " << mfr.X << std::endl;
		if(fingers[2].isValid()) {
			const Vector middleDirection = fingers[0].direction();
			x = (middleDirection.pitch() * RAD_TO_DEG * -1) + 11.344;
			middleFingerBone->setRotation(vector3df(x,mfr.Y,mfr.Z));
		}
		
		// INDEX
		const vector3df ifr = indexFingerBone->getRotation();
		//				std::cout << "Index: " << pfr.X << std::endl;
		
		if(fingers[3].isValid()) {
			const Vector indexDirection = fingers[2].direction();
			x = (indexDirection.pitch() * RAD_TO_DEG * -1) + 15.3019;
			indexFingerBone->setRotation(vector3df(x,ifr.Y,ifr.Z));
		}
		
		// THUMB
		const vector3df tfr = thumbBone->getRotation();
		//				std::cout << "Thumb: " << tfr.X << std::endl;
		
		if(fingers[4].isValid()) {
			const Vector thumbDirection = fingers[4].direction();
			x = (thumbDirection.pitch() * RAD_TO_DEG * -1) + 171.849;
			thumbBone->setRotation(vector3df(x,tfr.Y,tfr.Z));
		}
	}
}

void CPlayState::Draw(CGameEngine* game)
{
	int lastFPS = -1;
	
	bool soundplaying = false;
	
	if(game->device->run()) {

		if (game->device->isWindowActive())
		{
			u32 starttime = timer->getTime();
			
            //bulletHelper->UpdatePhysics(50);

			this->updateHand();
            
			driver->beginScene(true, true, video::SColor(0,200,200,200));
						
			smgr->drawAll();
            env->drawAll();
			
			driver->endScene();
			
			int fps = driver->getFPS();
			if (lastFPS != fps)
			{
				stringw str = L"Leap [";
				str += driver->getName();
				str += "] FPS:";
				str += fps;
				
				game->device->setWindowCaption(str.c_str());
				lastFPS = fps;
			}
			
			u32 deltaTime = timer->getTime() - starttime;
			//std::cout << deltaTime << std::endl;
			if(deltaTime < 10) {
				game->device->sleep(10 - deltaTime);
			}
		}
	}
}
