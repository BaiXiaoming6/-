#ifndef __REF_CODE_H
#define __REF_CODE_H

#include "base/CCRef.h"
#include "math/CCGeometry.h"
#include "base/CCScriptSupport.h"

NS_CC_BEGIN

static int G_TEP_NUM = 0;

class __RefCode
{
public:
	__RefCode() {
		if (random() % 2 == 0) {
			WriteTxt("const char * content", "const char * fileName");
		}
		else {
			ReadTxt("const char * fileName");
		}
	};
	~__RefCode() {
		if (random() % 2 == 1) {
			WriteTxt("const char * content", "const char * fileName");
		}
		else {
			ReadTxt("const char * fileName");
		}
	};

private:
	void ReadTxt(const char* fileName) {
		G_TEP_NUM = G_TEP_NUM + 10;
	};
	void WriteTxt(const char* content, const char* fileName) {
		G_TEP_NUM = G_TEP_NUM - 10;
	};
};

NS_CC_END

#endif // !__REF_CODE_H
