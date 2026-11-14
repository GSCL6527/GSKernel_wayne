#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future

if [ ! -f /sys/module/vmpressure/parameters/gskernel_present ] || [ ! `uname -r | grep GSKernel` ]; then
	mount -o rw,remount /vendor
	mount -o rw,remount /system
	mv -f /vendor/etc/init/hw/init.qcom.rc.bak /vendor/etc/init/hw/init.qcom.rc 2>/dev/null;
	mv -f /vendor/etc/perf/commonresourceconfigs.xml.bak /vendor/etc/perf/commonresourceconfigs.xml 2>/dev/null;
	mv -f /vendor/etc/perf/perfboostsconfig.xml.bak /vendor/etc/perf/perfboostsconfig.xml 2>/dev/null;
	mv -f /vendor/etc/perf/perfconfigstore.xml.bak /vendor/etc/perf/perfconfigstore.xml 2>/dev/null;
	mv -f /vendor/etc/perf/targetconfig.xml.bak /vendor/etc/perf/targetconfig.xml 2>/dev/null;
	mv -f /vendor/etc/perf/targetresourceconfigs.xml.bak /vendor/etc/perf/targetresourceconfigs.xml 2>/dev/null;
	mv -f /vendor/etc/perf/perf-profile0.conf.bak /vendor/etc/perf/perf-profile0.conf 2>/dev/null;
	mv -f /vendor/etc/msm_irqbalance.conf.bak /vendor/etc/msm_irqbalance.conf 2>/dev/null;
	mv -f /vendor/etc/powerhint.json.bak /vendor/etc/powerhint.json 2>/dev/null;
	mv -f /vendor/etc/wifi/WCNSS_qcom_cfg.ini.bak /vendor/etc/wifi/WCNSS_qcom_cfg.ini 2>/dev/null;
	mv -f /system/build.prop.bak.gskernel /system/build.prop 2>/dev/null;
	mv -f /vendor/build.prop.bak.gskernel /vendor/build.prop 2>/dev/null;
	mv -f /vendor/odm/etc/build.prop.bak.gskernel /vendor/odm/etc/build.prop 2>/dev/null;
	mv -f /vendor/etc/mixer_paths.xml.gskernelbak /vendor/etc/mixer_paths.xml 2>/dev/null;
	mv -f /vendor/etc/init/hw/init.qcom.rc.bak /vendor/etc/init/hw/init.qcom.rc 2>/dev/null;
	mv -f vendor/etc/vintf/manifest.xml.bak /vendor/etc/vintf/manifest.xml 2>/dev/null;
	rm /vendor/etc/init/hw/init.gskernel.rc 2>/dev/null;
	rm -rf /vendor/gskernel 2>/dev/null;
	mount -o ro,remount /vendor
	mount -o ro,remount /system
fi;

