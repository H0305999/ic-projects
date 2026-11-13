module edge_det (
    input      clk,
    input      rst_n,
    input      sig,     // 异步输入
    output     rise,    // 上升沿：1 拍宽
    output     fall     // 下降沿：1 拍宽
);
    reg s1, s2, s3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1 <= 1'b0;
            s2 <= 1'b0;
            s3 <= 1'b0;
        end else begin
            s1 <= sig;      // 第一级：冒险的一级
            s2 <= s1;       // 第二级：这里已经是稳定值
            s3 <= s2;       // 第三级：只为比较用
        end
    end

    assign rise = s2 & ~s3;   // 空1：这一拍是 1，上一拍是 0
    assign fall = ~s2 & s3;   // 空2：这一拍是 0，上一拍是 1
endmodule

