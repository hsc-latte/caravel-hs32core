/**
 * Copyright (c) 2020 The HSC Core Authors
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     https://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. SPDX-License-Identifier: Apache-2.0
 * 
 * @file   io_filter.v
 * @author Kevin Dai <kevindai02@outlook.com>
 * @date   Created on December 17 2020, 8:36 PM
 */

// TODO: Hahaha too lazy to do it
module io_filter (
    input wire clk,
    input wire rst,
    input wire a,
    output wire b,
    output reg rise,
    output reg fall
);
    reg[1:0] sync;
    assign b = sync[1];

    always @(posedge clk) if(rst) begin
        sync <= 0;
    end else begin
        sync <= { sync[0], a };
    end
    
    always @(posedge clk) if(rst) begin
        rise <= 0;
        fall <= 0;
    end else begin
        rise <= sync == 2'b01;
        fall <= sync == 2'b10;
    end
endmodule