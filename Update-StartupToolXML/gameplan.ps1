# switch Case Storage Service services
Flip-Services -vm 'sre01' -enable 'Symbotic Case Storage Service 5.3.132.1757' -disable 'Symbotic Case Storage Service 5.3.133.1814'

# switch Data Services services
Flip-Services -vm 'ods01' -enable 'Symbotic Data Services 5.3.132.13332-1' -disable 'Symbotic Data Services 5.3.132.13332'

# switch Pallet Build Planner services
Flip-Services -vm 'pbp01' -enable 'Symbotic Pallet Build Planner 22.1.1.518' -disable 'Symbotic Pallet Build Planner 22.12.1.537'

# switch Pallet Build Planner services
Flip-Services -vm 'pbp02' -enable 'Symbotic Pallet Build Planner 22.1.1.518' -disable 'Symbotic Pallet Build Planner 22.12.1.537'

# switch Pallet Build Planner services
Flip-Services -vm 'pbp03' -enable 'Symbotic Pallet Build Planner 22.1.1.518' -disable 'Symbotic Pallet Build Planner 22.12.1.537'

# switch Pallet Build Planner services
Flip-Services -vm 'pbp04' -enable 'Symbotic Pallet Build Planner 22.1.1.518' -disable 'Symbotic Pallet Build Planner 22.12.1.537'

# switch Pallet Build Planner services
Flip-Services -vm 'pbp05' -enable 'Symbotic Pallet Build Planner 22.1.1.518' -disable 'Symbotic Pallet Build Planner 22.12.1.537'

# switch Pallet Build Planner services
Flip-Services -vm 'pbp06' -enable 'Symbotic Pallet Build Planner 22.1.1.518' -disable 'Symbotic Pallet Build Planner 22.12.1.537'

# switch Pallet Build Planner services
Flip-Services -vm 'pbp07' -enable 'Symbotic Pallet Build Planner 22.1.1.518' -disable 'Symbotic Pallet Build Planner 22.12.1.537'

# switch Pallet Build Planner services
Flip-Services -vm 'pbp08' -enable 'Symbotic Pallet Build Planner 22.1.1.518' -disable 'Symbotic Pallet Build Planner 22.12.1.537'

# switch Pallet Sequencer services
Flip-Services -vm 'pseq01' -enable 'Symbotic Pallet Sequencer 12.4.2.1486-1' -disable 'Symbotic Pallet Sequencer 12.4.2.1486'

# switch IM01 symlink
Switch-Symlink -vmName 'im01' -location 'E:\Program Files\Symbotic\Integration Manager 1.4.151' -symlinkName 'SiteConfigs' -target 'E:\SiteConfigs 5.3.134.12'

