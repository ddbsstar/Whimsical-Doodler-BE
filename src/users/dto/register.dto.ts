import { IsEmail, Length, IsString, IsNotEmpty } from 'class-validator';

export class RegisterUserDto {
  @IsNotEmpty({ message: '邮箱不能为空' })
  @IsEmail({}, { message: '请输入有效的邮件地址' })
  email: string;

  @IsNotEmpty({ message: '密码不能为空' })
  @Length(8, 20, { message: '密码长度必须在8-20字符之间' })
  @IsString({ message: '密码必须是字符串' })
  password: string;
}
