// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright(C) 2020 Linaro Limited. All rights reserved.
 * Author: Mike Leach <mike.leach@linaro.org>
 */

#include "coresight-config.h"
#include "coresight-syscfg.h"

 /* create an alternate autofdo configuration */

 /* we will provide 4 sets of preset parameter values */
#define AFDO2_NR_PRESETS	4
/* the total number of parameters in used features - strobing has 2 */
#define AFDO2_NR_PARAM_SUM	2

static const char* afdo2_ref_names[] = {
	//"strobing",
};

/*
 * set of presets leaves strobing window constant while varying period to allow
 * experimentation with mark / space ratios for various workloads
 */


static struct cscfg_feature_desc* sample_feats[] = {
	NULL
};

static struct cscfg_config_desc* sample_cfgs[] = {
	&afdo2,
	NULL
};



/* module init and exit - just load and unload configs */
static int cscfg_sample_init(void)
{
	return 0;
}

static void cscfg_sample_exit(void)
{
	cscfg_unload_config_sets(&mod_owner);
}

//module_init(cscfg_sample_init);
//module_exit();

int func1();
MODULE_AUTHOR("Mike Leach <mike.leach@linaro.org>");
MODULE_DESCRIPTION("CoreSight Syscfg Example");