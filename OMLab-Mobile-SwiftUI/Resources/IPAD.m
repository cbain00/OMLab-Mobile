% IPAD.m
%
% Summary:
% This class represents a UDP object that facilitates communication with a 
% device using a UDP connection (User Datagram Protocol). It provides methods for
% establishing a connection, setting the session name, starting and
% stopping recording, sending event messages, and closing the connection.
% 
% The IPAD class is designed to interact with a device running OM-Lab Mobile.
% It handles the UDP communication necessary for sending commands and receiving 
% data from the device. The class supports functionalities such
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
        % Establish connection to UDP client
        function Connect(this, ip)
            this.ipAdd = ip;
            this.port = 8000;
            this.u = udpport;
    
            try
                % Attempt to establish the connection
                fopen(this.u);                
                fprintf('Connection established successfully.\n');

                % Start connection status monitoring
                fprintf('Beginning connection monitoring...\n')
                this.StartConnectionStatusMonitoring();

            catch
                fprintf('\nFailed to establish connection.\n');
            end
        end


        % set name for recording session
        function SetSessionName(this, sessionName)
         %  write(this.u,['ChangeSetting?settingName=SessionName&value=' sessionName],"uint8",this.ipAdd,this.port)
        end


        function StartRecording(this)
           % Start recording through UDP client
           disp('Starting Recording...')
           response = this.sendMessage('StartRecording');
           disp(response)
        end

        
        function StopRecording(this)
           % Stop recording
           disp('Stopping Recording...')
           response = this.sendMessage('StopRecording');
           disp(response)
        end

        
        % Record occurring event during session
        function RecordEvent(this, message)
           response = this.sendMessage(message);
           disp(response)
        end


        % sending function for udp validation
        function response = sendMessage(this, message)
           tic;
           write(this.u, message, "uint8", this.ipAdd,this.port);
           while (this.u.NumBytesAvailable == 0)
               seconds = toc;
               if (seconds >= 0.5)
                   error('Connection timeout.')
               end
           end
           data = read(this.u,this.u.NumBytesAvailable,"uint8");
           response = char(data);
        end

        
        % close connection to client
        function Close(this)
            if isempty(this.u) || ~isvalid(this.u) || strcmp(this.u.Status, 'closed')
                disp('Invalid: No connection to disconnect.')
                return;
            end
            
            this.StopConnectionStatusMonitoring();
            this.u.delete;
            disp('Connection disconnected successfully.');
        end

        
        % start timer to let user know if connection has been dropped
        % during session
        function StartConnectionStatusMonitoring(this)
            % Create a timer to periodically check the connection status
            this.connectionStatusTimer = timer('ExecutionMode', 'fixedRate', ...
                'Period', 5, ...
                'TimerFcn', @this.CheckConnectionStatus);
            
            % Start the timer
            start(this.connectionStatusTimer);
        end

        
        % if connection has dropped, print message to console
        % (helper function for StartConnectionStatusMonitoring())
        function CheckConnectionStatus(this, ~, ~)
            if ~strcmp(this.u.Status, 'open')
                fprintf('Connection lost.\n');
                
                % Stop the connection status monitoring
                this.StopConnectionStatusMonitoring();
            end
        end
        
        
        % delete connection timer (helper function for 
        % StartConnectionStatusMonitoring())
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
