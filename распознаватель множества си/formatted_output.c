#include "coresight-config.h"
#include "coresight-syscfg.h"
#define AFDO2_NR_PRESETS	4
#define AFDO2_NR_PARAM_SUM	2
static const char *afdo2_ref_names[] = {
    }
;
static struct cscfg_feature_desc *sample_feats[] = {
    NULL }
;
static struct cscfg_config_desc *sample_cfgs[] = {
     &afdo2, NULL }
;
static int cscfg_sample_init(void) {
    return 0;
    }
static void cscfg_sample_exit(void) {
    cscfg_unload_config_sets(&mod_owner);
    }
int func1();
MODULE_AUTHOR("Mike Leach <mike.leach@linaro.org>");
MODULE_DESCRIPTION("CoreSight Syscfg Example");
