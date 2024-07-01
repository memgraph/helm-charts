ADD COORDINATOR 2 WITH CONFIG {"bolt_server": "coord2:7691", "coordinator_server": "coord2:10112"};
ADD COORDINATOR 3 WITH CONFIG {"bolt_server": "coord3:7692", "coordinator_server": "coord3:10113"};

REGISTER INSTANCE instance_1 WITH CONFIG {"bolt_server": "instance1:7687", "management_server": "instance1:10011", "replication_server": "instance1:10001"};
REGISTER INSTANCE instance_2 WITH CONFIG {"bolt_server": "instance2:7688", "management_server": "instance2:10012", "replication_server": "instance2:10002"};
REGISTER INSTANCE instance_3 WITH CONFIG {"bolt_server": "instance3:7689", "management_server": "instance3:10013", "replication_server": "instance3:10003"};
SET INSTANCE instance_3 TO MAIN;
