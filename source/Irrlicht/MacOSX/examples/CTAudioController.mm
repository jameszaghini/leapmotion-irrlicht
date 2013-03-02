//
//  CTAudioController.cpp
//  Contratempo
//
//  Created by James Zaghini on 3/01/13.
//
//

#include "CTAudioController.h"
#include <Foundation/Foundation.h>

CTAudioController CTAudioController::m_AudioController;


void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK)
    {
        printf("FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
        exit(-1);
    }
}

void CTAudioController::play(std::string filename)
{
    FMOD::System     *system;
    FMOD::Sound      *sound;
    FMOD::Channel    *channel = 0;
    FMOD_RESULT       result;
    int               key;
    unsigned int      version;
	
    /*
	 Global Settings
	 */
    result = FMOD::System_Create(&system);
    ERRCHECK(result);
	
    result = system->getVersion(&version);
    ERRCHECK(result);
	
    if (version < FMOD_VERSION)
    {
        printf("Error!  You are using an old version of FMOD %08x.  This program requires %08x\n", version, FMOD_VERSION);
    }
	
    result = system->init(1, FMOD_INIT_NORMAL, 0);
    ERRCHECK(result);
	
    [[NSFileManager defaultManager]
     changeCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	
    result = system->createSound(filename.c_str(), (FMOD_MODE)(FMOD_SOFTWARE | FMOD_2D | FMOD_CREATESTREAM), 0, &sound);
    ERRCHECK(result);
	
    /*
	 Play the sound.
	 */
	
    result = system->playSound(FMOD_CHANNEL_FREE, sound, false, &channel);
    ERRCHECK(result);
}

void gunshot()
{
    FMOD::System     *system;
    FMOD::Sound      *sound;
    FMOD::Channel    *channel = 0;
    FMOD_RESULT       result;
    int               key;
    unsigned int      version;
	
    /*
	 Global Settings
	 */
    result = FMOD::System_Create(&system);
    ERRCHECK(result);
	
    result = system->getVersion(&version);
    ERRCHECK(result);
	
    if (version < FMOD_VERSION)
    {
        printf("Error!  You are using an old version of FMOD %08x.  This program requires %08x\n", version, FMOD_VERSION);
    }
	
    result = system->init(1, FMOD_INIT_NORMAL, 0);
    ERRCHECK(result);
	
    result = system->createSound("ball.wav", (FMOD_MODE)(FMOD_SOFTWARE | FMOD_2D | FMOD_CREATESTREAM), 0, &sound);
    ERRCHECK(result);
	
    /*
	 Play the sound.
	 */
	
    result = system->playSound(FMOD_CHANNEL_FREE, sound, false, &channel);
    ERRCHECK(result);
}