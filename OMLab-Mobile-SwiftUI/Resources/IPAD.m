% IPAD.m
%
% Summary:
% This class represents a UDP object that facilitates communication with a 
% device using UDP (User Datagram Protocol). It provides methods for 
% establishing a connection, setting the session name, starting and 
% stopping recording, sending event messages, and closing the connection.
% 
% The IPAD class is designed to interact with a device running an eye tracking
% application. It handles the UDP communication necessary for sending commands
% and receiving data from the device. The class supports functionalities such
% as connecting to the device, setting the session name, initiating recording,
% stopping recording, sending custom event messages, and closing the
% connection.
% 
%
% Example usage:
%   % Create an IPAD object and establish connection
%   ipad = IPAD();
%   ipad.Connect('192.168.0.1');
%   
%   % Set session name
%   ipad.SetSessionName('Session1');
%   
%   % Start recording
%   ipad.StartRecording();
%   
%   % Send an event message
%   ipad.RecordEvent('ButtonPressed');
%   
%   % Stop recording
%   ipad.StopRecording();
%   
%   % Close the connection
%   ipad.Close();

classdef IPAD  < handle    
    properties
        ipAdd
        port
        u
        connectionStatusTimer
    end
    
    methods
        function Connect(this, ip)
            this.ipAdd = ip;
            this.port = 8000;
            this.u = udpport;
    
        % Attempt to establish the connection
            try
                fopen(this.u);                
                % Start connection status monitoring
                this.StartConnectionStatusMonitoring();

                fprintf('Connection established successfully.\n');

            catch
                fprintf('Failed to establish connection.\n');
            end
        end

        function SetSessionName(this, sessionName)
         %  write(this.u,['ChangeSetting?settingName=SessionName&value=' sessionName],"uint8",this.ipAdd,this.port)
        end
        
        function StartRecording(this)
           disp('Starting Recording...')
           write(this.u,'StartRecording',"uint8",this.ipAdd,this.port);
           data = read(this.u,this.u.NumBytesAvailable,"uint8");
           disp(data)
        end
        
        function StopRecording(this)
           disp('Stopping Recording...')
           write(this.u,'StopRecording',"uint8",this.ipAdd,this.port);
        end
        
        function RecordEvent(this, message)
           write(this.u,message,"uint8",this.ipAdd,this.port);
        end  
        
        function Close(this)
           this.u.delete
           disp('Connection disconnected successfully.')
        end

        function StartConnectionStatusMonitoring(this)
            % Create a timer to periodically check the connection status
            this.connectionStatusTimer = timer('ExecutionMode', 'fixedRate', ...
                'Period', 5, ...
                'TimerFcn', @this.CheckConnectionStatus);
            
            % Start the timer
            start(this.connectionStatusTimer);
        end
        
        function CheckConnectionStatus(this, ~, ~)
            if ~strcmp(this.u.Status, 'open')
                fprintf('Connection lost.\n');
                
                % Stop the connection status monitoring
                this.StopConnectionStatusMonitoring();
            end
        end
        
        function StopConnectionStatusMonitoring(this)
            % Stop and delete the connection status timer
            if ~isempty(this.connectionStatusTimer)
                stop(this.connectionStatusTimer);
                delete(this.connectionStatusTimer);
                this.connectionStatusTimer = [];
            end
        end

    end
    
    methods(Static = true)
    end
    
end



