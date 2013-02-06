//
//  CTAudioController.h
//  Contratempo
//
//  Created by James Zaghini on 3/01/13.
//
//

#ifndef __Contratempo__CTAudioController__
#define __Contratempo__CTAudioController__

#include <iostream>
#include <string>
#include "fmod.hpp"
#include "fmod_errors.h"

class CTAudioController
{
public:
	
	static CTAudioController* Instance() {
		return &m_AudioController;
	}
	
	void play(std::string filename);
	
protected:
	CTAudioController() { }
	
private:
	static CTAudioController m_AudioController;
};

#endif /* defined(__Contratempo__CTAudioController__) */
