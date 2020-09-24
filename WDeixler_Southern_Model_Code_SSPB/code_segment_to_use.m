%Local Measurement
[Iabc_compensation,Iabc_power,ZCMMIN,Device_Losses] = PBAL_func_withlosses(V_ABC_before1,I_ABC_before1,50e3);
%Substation Measurement
% [Iabc_compensation,Iabc_power,ZCMMIN,Device_Losses] = PBAL_func_withlosses(V_Sub_ABC_before,I_Sub_ABC_before.*[1; .3; 1],50e3);


Iabc_shunt=Iabc_compensation+Iabc_power;

V_PB=V_ABC_before1;

for n=1:6    
% S_inj=V_PB.*(conj(Iabc_new-I_before))/rescale_V;
S_inj=V_PB.*(conj(Iabc_shunt));

if n>1
    type='Edit';
else
    type='New';
end

DSSText.Command=[type,' Generator.671a1 Phases=1 Bus1=', PBA_Node '.1 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=' num2str(real(S_inj(1))/1e3)];
DSSText.Command=[type,' Generator.671a2 Phases=1 Bus1=', PBA_Node '.1 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=' num2str(imag(S_inj(1))/1e3)];
DSSText.Command=[type,' Generator.671b1 Phases=1 Bus1=', PBA_Node '.2 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=' num2str(real(S_inj(2))/1e3)];
DSSText.Command=[type,' Generator.671b2 Phases=1 Bus1=', PBA_Node '.2 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=' num2str(imag(S_inj(2))/1e3)];
DSSText.Command=[type,' Generator.671c1 Phases=1 Bus1=', PBA_Node '.3 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kVar=0 kW=' num2str(real(S_inj(3))/1e3)];
DSSText.Command=[type,' Generator.671c2 Phases=1 Bus1=', PBA_Node '.3 ', 'kV=',num2str(Vbaseold/1e3), ' model=1 kW=0 kVar=' num2str(imag(S_inj(3))/1e3)];

DSSText.Command='calcv';% Z Ding added

DSSText.Command='set number=1 stepsize=15m hour=0 sec=0';
DSSText.Command=['set hour=',num2str(0/4),' h=',num2str(900*step),' sec=',num2str(0)];

DSSText.Command='solve';

DSSCircuit.SetActiveBus(PBA_Node); % This is the node where voltage is measured for voltage unbalance
DSSActiveBus=DSSCircuit.ActiveBus;
Vbus_new=DSSActiveBus.Voltages;
V_downABC_new=[Vbus_new(1)+j*Vbus_new(2); Vbus_new(3)+j*Vbus_new(4); Vbus_new(5)+j*Vbus_new(6)];
V_new=ABC_to_SEQ*V_downABC_new;

error(:,n)=V_downABC_new-V_PB;

V_PB=V_downABC_new;

end

